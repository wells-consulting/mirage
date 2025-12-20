//
// Copyright 2025 Wells Consulting.
// This file is part of Mirage and is released under the MIT License.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public actor HTTPClient {

    private let urlSession: URLSession
    private var additionalHeaders: [String: String] = [:]
    private let logOptions: LogOptions
    private let jsonCoder: JSONCoder
    private let logger = PlatformLogger(category: "HTTPClient")

    // MARK: Initializer

    public struct LogOptions: OptionSet, Sendable {

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let request = LogOptions(rawValue: 1 << 1)
        public static let requestBody = LogOptions(rawValue: 1 << 2)
        public static let response = LogOptions(rawValue: 1 << 3)
        public static let responseBody = LogOptions(rawValue: 1 << 4)

        public static let logAll: LogOptions = [.request, .requestBody, .response, .responseBody]
    }

    public struct Configuration: Sendable {

        let jsonCoder: JSONCoder
        let logOptions: LogOptions
        let headers: [String: String]
        let oAuthToken: OAuthToken?

        public init(
            headers: [String: String] = [:],
            oAuthToken: OAuthToken? = nil,
            jsonCoder: JSONCoder = .shared,
            logOptions: LogOptions = []
        ) {
            self.headers = headers
            self.oAuthToken = oAuthToken
            self.jsonCoder = jsonCoder
            self.logOptions = logOptions
        }
    }

    public init(configuration: Configuration = .init()) {
        let urlSessionConfiguration = URLSessionConfiguration.default
        urlSessionConfiguration.httpAdditionalHeaders = configuration.headers
        urlSessionConfiguration.timeoutIntervalForRequest = ClientRequest.defaultTimeout
        urlSessionConfiguration.httpCookieStorage = HTTPCookieStorage.shared

        self.urlSession = URLSession(configuration: urlSessionConfiguration)
        self.logOptions = configuration.logOptions
        self.jsonCoder = configuration.jsonCoder

        if let accessToken = configuration.oAuthToken?.accessToken {
            additionalHeaders["Authorization"] = "Bearer \(accessToken)"
        }
    }

    // MARK: - Dispatch

    private nonisolated(unsafe) static let requestCounter = RequestCounter()

    private func sendRequest(_ clientRequest: ClientRequest) async throws -> (Data?, HTTPURLResponse) {
        let logOptions = clientRequest.logOptions ?? logOptions

        if logOptions.contains(.request) {
            if logOptions.contains(.requestBody), let summary = clientRequest.payloadSummary {
                logger.debug("\(clientRequest.requestSummary): \(summary)")
            } else {
                logger.debug(clientRequest.requestSummary)
            }
        }

        let shouldLogResponse = logOptions.contains(.response)
        let shouldLogResponseBody = logOptions.contains(.responseBody)

        var urlRequest = clientRequest.urlRequest

        for (name, value) in additionalHeaders {
            if urlRequest.allHTTPHeaderFields == nil {
                urlRequest.allHTTPHeaderFields = [name: value]
            } else {
                urlRequest.allHTTPHeaderFields?[name] = value
            }
        }

        let (data, urlResponse) = try await urlSession.data(for: urlRequest)

        let httpResponse = ClientResponse(clientRequest: clientRequest, urlResponse: urlResponse, data: data)

        if shouldLogResponse {
            let message = httpResponse.logDescription(includeResponseBody: shouldLogResponseBody)
            logger.debug(message)
        }

        // Unrecoverable error: response must be an HTTPURLResponse

        guard let httpURLResponse = urlResponse as? HTTPURLResponse else {
            throw Self.Error(clientRequest: clientRequest, httpURLResponse: nil, responseData: data)
        }

        // Unrecoverable error: status code must be known

        guard let statusCode = StatusCode(rawValue: httpURLResponse.statusCode) else {
            throw Self.Error(clientRequest: clientRequest, httpURLResponse: httpURLResponse, responseData: data)
        }

        // Failure is not an option

        guard statusCode.isSuccess else {
            throw Self.Error(clientRequest: clientRequest, httpURLResponse: httpURLResponse, responseData: data)
        }

        return (data, httpURLResponse)
    }

    // MARK: - Headers

    public func header(_ name: String) -> String? {
        additionalHeaders[name]
    }

    public func setHeader(name: String, value: String?) {
        if let value {
            additionalHeaders.updateValue(value, forKey: name)
        } else {
            removeHeader(name)
        }
    }

    public func removeHeader(_ name: String) {
        setHeader(name: name, value: nil)
    }

    // MARK: - Helpers

    public func setAuthToken(_ authToken: OAuthToken?) {
        if let accessToken = authToken?.accessToken {
            setHeader(name: "Authorization", value: "Bearer \(accessToken)")
        } else {
            removeHeader("Authorization")
        }
    }
}

// MARK: - Content Type

extension HTTPClient {

    enum ContentType: Sendable {
        case json
        case multipartForm(String)
        case urlEncodedForm
        case text
        case binary

        var value: String {
            switch self {
            case .json:
                "application/json"
            case let .multipartForm(boundary):
                "multipart/form-data; boundary=\(boundary)"
            case .urlEncodedForm:
                "application/x-www-form-urlencoded"
            case .text:
                "text/plain"
            case .binary:
                "application/octet-stream"
            }
        }

        init?(_ text: String) {
            switch text {
            case "application/json":
                self = .json
            case _ where text.hasPrefix("/multipart/form-data; boundary="):
                let matches = text.matches(of: /multipart\/form-data; boundary=(.*)/)
                if matches.count == 2 {
                    self = .multipartForm(String(text[matches[1].range]))
                } else {
                    return nil
                }
            case "application/x-www-form-urlencoded":
                self = .urlEncodedForm
            case "text/plain":
                self = .text
            case "application/octet-stream":
                self = .binary
            default:
                return nil
            }
        }
    }
}

// MARK: ClientRequest

extension HTTPClient {

    fileprivate struct ClientRequest {
        let id: Int
        let urlRequest: URLRequest
        let requestSummary: String
        let payloadSummary: String?
        let timestamp: Date = .init()
        let logOptions: LogOptions?

        static let defaultTimeout: TimeInterval = 30.0 * 1000.0 // 30s

        init(urlRequest: URLRequest, payload: Payload?, logOptions: LogOptions? = nil) {
            self.id = requestCounter.increment()

            self.urlRequest = urlRequest
            self.logOptions = logOptions
            self.payloadSummary = payload?.summary

            var summary = "[\(id)] -> " + (urlRequest.httpMethod ?? "NO_METHOD")

            if let url = urlRequest.url {
                summary += " " + url.description
            }

            if let typeName = payload?.typeName {
                summary += " " + typeName
            }

            if let data = urlRequest.httpBody {
                summary += ", \(data.count.formatted(.byteCount(style: .memory)))"
            }

            self.requestSummary = summary
        }

        init(url: URL, method: Method, payload: Payload, accept: ContentType, logOptions: LogOptions? = nil, headers: [String: String] = [:], timeout: TimeInterval? = nil) {

            var urlRequest = URLRequest(url: url)

            urlRequest.httpMethod = method.rawValue
            urlRequest.timeoutInterval = timeout ?? Self.defaultTimeout
            urlRequest.addValue(accept.value, forHTTPHeaderField: "Accept")
            if let contentType = payload.contentType {
                urlRequest.addValue(contentType.value, forHTTPHeaderField: "Content-Type")
            }

            self.init(urlRequest: urlRequest, payload: payload, logOptions: logOptions)
        }
    }

    public enum Method: String, Sendable {
        case delete = "DELETE"
        case get = "GET"
        case patch = "PATCH"
        case post = "POST"
        case put = "PUT"
    }

    struct Payload: Summarizable, Sendable {
        let data: Data
        let contentType: ContentType?
        let typeName: String?
        let summary: String?

        static let none = Payload(
            data: Data(capacity: 0),
            contentType: nil,
            typeName: nil,
            summary: nil
        )
    }
}

// MARK: ClientResponse

extension HTTPClient {

    fileprivate struct ClientResponse {

        let requestID: Int
        let requestTimestamp: Date
        let statusCode: StatusCode?
        let data: Data?

        let timestamp: Date = .init()

        init(clientRequest: ClientRequest, urlResponse: URLResponse?, data: Data?) {
            self.requestID = clientRequest.id
            self.requestTimestamp = clientRequest.timestamp
            self.statusCode =
                if let rawValue = (urlResponse as? HTTPURLResponse)?.statusCode {
                    StatusCode(rawValue: rawValue)
                } else {
                    nil
                }
            self.data = data
        }

        func logDescription(includeResponseBody: Bool) -> String {
            var parts = [String]()

            var forceIncludeResponseBody = false
            if let statusCode {
                parts.append("[\(requestID)] <- " + statusCode.description)
                forceIncludeResponseBody = !statusCode.isSuccess && statusCode != .notFound
            } else {
                parts.append("[\(requestID)]")
            }

            if let data {
                parts.append(data.count.formatted(.byteCount(style: .memory)))
            }

            parts.append(Date.debugDurationString(from: requestTimestamp, to: timestamp))

            var responseDescription: String?

            if forceIncludeResponseBody || includeResponseBody, let data, !data.isEmpty {
                parts.append(data.count.formatted(.byteCount(style: .memory)))
                if let text = String(data: data, encoding: .utf8) {
                    responseDescription = "\n----\n" + text + "\n-----"
                }
            }

            var description = parts.joined(separator: ", ")

            if let responseDescription {
                description.append(responseDescription)
            }

            return description
        }
    }

    public enum StatusCode: Int, Codable, CustomStringConvertible, Sendable {

        // 1XX

        case `continue` = 100
        case switchingProtocols = 101
        case processing = 102

        // 2XX

        case ok = 200
        case created = 201
        case accepted = 202
        case nonAuthoritativeInformation = 203
        case noContent = 204
        case resetContent = 205
        case partialContent = 206
        case multiStatus = 207 // WebDAV
        case alreadyReported = 208 // WebDAV
        case imUsed = 226

        // 3XX

        case multipleChoices = 300
        case movedPermanently = 301
        case found = 302
        case seeOther = 303
        case notModified = 304
        case useProxy = 305
        case switchProxy = 306
        case temporaryRedirect = 307
        case permanentRedirect = 308

        // 4XX

        case badRequest = 400
        case unauthorized = 401
        case paymentRequired = 402
        case forbidden = 403
        case notFound = 404
        case methodNotAllowed = 405
        case notAcceptable = 406
        case proxyAuthenticationRequired = 407
        case requestTimeout = 408
        case conflict = 409
        case gone = 410
        case lengthRequired = 411
        case preconditionFailed = 412
        case payloadTooLarge = 413
        case uriTooLong = 414
        case unsupportedMediaType = 415
        case rangeNotSatisfiable = 416
        case expectationFailed = 417
        case imATeapot = 418
        case misdirectedRequest = 421
        case unprocessableEntity = 422 // WebDAV
        case locked = 423 // WebDAV
        case failedDependency = 424 // WebDAV
        case upgradeRequired = 426
        case preconditionRequired = 428
        case tooManyRequests = 429
        case requestHeaderFieldsTooLarge = 431
        case unavailableForLegalReasons = 451

        // 5XX

        case internalServerError = 500
        case notImplemented = 501
        case badGateway = 502
        case serviceUnavailable = 503
        case gatewayTimeout = 504
        case httpVersionNotSupported = 505
        case variantAlsoNegotiates = 506
        case insufficientStorage = 507 // WebDAV
        case loopDetected = 508 // WebDAV
        case notExtended = 510
        case networkAuthenticationRequired = 511

        public var isSuccess: Bool { rawValue >= 200 && rawValue < 299 }
        public var isClientError: Bool { rawValue >= 400 && rawValue < 499 }
        public var isServerError: Bool { rawValue >= 500 && rawValue < 599 }

        public var description: String {
            switch self {
            // 10x
            case .continue:
                "100 Continue"
            case .switchingProtocols:
                "101 Switching Protocols"
            case .processing:
                "102 Processing"
            // 20x
            case .ok:
                "200 OK"
            case .created:
                "201 Created"
            case .accepted:
                "202 Accepted"
            case .nonAuthoritativeInformation:
                "203 Non-Authoritative Information"
            case .noContent:
                "204 No Content"
            case .resetContent:
                "205 Reset Content"
            case .partialContent:
                "206 Partial Content"
            case .multiStatus:
                "207 Mult-status (WebDAV)"
            case .imUsed:
                "226 IM Used"
            case .alreadyReported:
                "208 Already Reported (WebDAV)"
            // 30x
            case .multipleChoices:
                "300 Multiple Choices"
            case .movedPermanently:
                "301 Moved Permantley"
            case .found:
                "302 Found"
            case .seeOther:
                "303 See Other"
            case .notModified:
                "304 Not Modified"
            case .useProxy:
                "305 Use Proxy"
            case .switchProxy:
                "306 Switch Proxy"
            case .temporaryRedirect:
                "307 Temporary Redirect"
            case .permanentRedirect:
                "308 Permanent Redirect"
            // 40x
            case .badRequest:
                "400 Bad Request"
            case .unauthorized:
                "401 Unauthorized"
            case .paymentRequired:
                "402 Payment Required"
            case .forbidden:
                "403 Forbidden"
            case .notFound:
                "404 Not Found"
            case .methodNotAllowed:
                "405 Method Not Allowed"
            case .notAcceptable:
                "406 Not Acceptable"
            case .proxyAuthenticationRequired:
                "407 Proxy Authenticion Required"
            case .requestTimeout:
                "408 Request Timeout"
            case .conflict:
                "409 Conflict"
            case .gone:
                "410 Gone"
            case .lengthRequired:
                "411 Length Required"
            case .preconditionFailed:
                "412 Precondition Failed"
            case .payloadTooLarge:
                "413 Payload Too Large"
            case .uriTooLong:
                "414 URI Too Long"
            case .unsupportedMediaType:
                "415 Unsuported Media Type"
            case .rangeNotSatisfiable:
                "416 Range Not Satisfiable"
            case .expectationFailed:
                "417 Expectation Failed"
            case .imATeapot:
                "418 I'm a Teapot"
            case .misdirectedRequest:
                "421 Misdirected Request"
            case .unprocessableEntity:
                "422 Unprocessable Entity (WebDAV)"
            case .locked:
                "423 Locked (WebDAV)"
            case .failedDependency:
                "424 Failed Dependency (WebDAV)"
            case .upgradeRequired:
                "426 Upgrade Required"
            case .preconditionRequired:
                "428 Precondition Required"
            case .tooManyRequests:
                "429 Too Many Requests"
            case .requestHeaderFieldsTooLarge:
                "431 Request Header Fields Too Large"
            case .unavailableForLegalReasons:
                "451 Unavailable For Legal Reasons"
            // 50x
            case .internalServerError:
                "500 Internal Server Error"
            case .notImplemented:
                "501 Not Implemented"
            case .badGateway:
                "502 Bad Gateway"
            case .serviceUnavailable:
                "503 Service Unavailable"
            case .gatewayTimeout:
                "504 Gateway Timeout"
            case .httpVersionNotSupported:
                "505 HTTP Version Not Supported"
            case .variantAlsoNegotiates:
                "506 Variant Also Negotiates"
            case .insufficientStorage:
                "507 Insufficient Storage (WebDAV)"
            case .loopDetected:
                "508 Loop Dected (WebDAV)"
            case .notExtended:
                "510 Not Extended"
            case .networkAuthenticationRequired:
                "511 Network Authentication Required"
            }
        }
    }
}

// MARK: - Error

public extension HTTPClient {

    struct Error: MirageError {

        /// Localized title text
        public let title: String?

        /// Localized error text
        public let description: String

        /// Underlying URLRequest
        public let urlRequest: URLRequest?

        /// Underlying URLResponse
        public let httpURLResponse: HTTPURLResponse?

        /// Duration from creation of the request to creation of the response
        public let responseTimeRange: Range<Date>?

        /// HTTP response status code
        public var statusCode: StatusCode? {
            if let statusCodeRawValue = httpURLResponse?.statusCode {
                StatusCode(rawValue: statusCodeRawValue)
            } else {
                nil
            }
        }

        /// HTTP response data received
        public let responseData: Data?

        /// HTTP response header
        public func value(forHeader name: String) -> String? {
            httpURLResponse?.value(forHTTPHeaderField: name)
        }

        /// Wrapped error
        public let underlyingError: (any Swift.Error)?

        /// Error-specific context
        public let context: [String: any Sendable]?

        fileprivate init(_ description: String, title: String? = nil, urlRequest: URLRequest? = nil, httpURLResponse: HTTPURLResponse? = nil, responseData: Data? = nil, responseTimeRange: Range<Date>? = nil, underlyingError: (any Swift.Error)? = nil, context: [String: any Sendable]? = nil) {
            self.title = title
            self.description = description
            self.urlRequest = urlRequest
            self.httpURLResponse = httpURLResponse
            self.responseData = responseData
            self.responseTimeRange = responseTimeRange
            self.underlyingError = underlyingError
            self.context = context
        }

        fileprivate init(clientRequest: ClientRequest, httpURLResponse: HTTPURLResponse?, responseData: Data?, title: String? = nil, responseTimeRange: Range<Date>? = nil, underlyingError: (any Swift.Error)? = nil, context: [String: any Sendable]? = nil) {

            self.urlRequest = clientRequest.urlRequest
            self.httpURLResponse = httpURLResponse
            self.responseData = responseData
            self.title = title
            self.responseTimeRange = responseTimeRange
            self.underlyingError = underlyingError
            self.context = context

            var parts: [String] = []

            if let methodRawValue = clientRequest.urlRequest.httpMethod, let method = Method(rawValue: methodRawValue) {
                if let statusCodeRawValue = httpURLResponse?.statusCode,
                   let statusCode = StatusCode(rawValue: statusCodeRawValue)
                {
                    parts.append("HTTP \(method.rawValue) failed with \(statusCode.description).")
                } else {
                    parts.append("HTTP \(method.rawValue) failed.")
                }
            } else {
                parts.append("HTTP request failed.")
            }

            if let responseData {
                parts.append("Received " + responseData.count.formatted(.byteCount(style: .memory)) + " bytes.")
            }

            if let responseTimeRange {
                parts.append("Completed in \(responseTimeRange.debugDurationString).")
            }

            self.description = parts.joined(separator: "\n")
        }

        // MARK: Factory Methods

        static func missingURL(context: String? = nil) -> Self {
            if let context {
                .init("No URL found in \(context).", title: "Missing URL")
            } else {
                .init("No URL found.", title: "Missing URL")
            }
        }

        static func malformedURL(_ string: String) -> Self {
            .init("Could not create URL from '\(string)'", title: "Invalid URL Format")
        }
    }
}

// MARK: - Simple Request

public extension HTTPClient {
    func data(for urlRequest: URLRequest) async throws -> (Data?, HTTPURLResponse) {
        try await sendRequest(.init(urlRequest: urlRequest, payload: nil))
    }
}

// MARK: - GET

public extension HTTPClient {

    func get(_ url: URL, headers: [String: String] = [:]) async throws -> Data? {
        let (data, _) = try await process(.get, url: url, headers: headers)
        return data
    }

    func get<ReceivedObject: Decodable>(_ url: URL, headers: [String: String] = [:], context: [CodingUserInfoKey: Sendable]?) async throws -> ReceivedObject {
        try await process(.get, data: nil, url: url, headers: headers, context: context)
    }
}

// MARK: - POST

public extension HTTPClient {

    func post(_ url: URL, headers: [String: String] = [:]) async throws -> Data? {
        try await process(.post, url: url, headers: headers).0
    }

    func post<ReceivedObject: Decodable>(_ data: Data, to url: URL, headers: [String: String] = [:], context: [CodingUserInfoKey: Sendable]? = nil) async throws -> ReceivedObject {
        try await process(.post, data: data, url: url, headers: headers, context: context)
    }

    func post(_ object: some Encodable, to url: URL, headers: [String: String] = [:]) async throws -> Data? {
        try await process(.post, object: object, url: url, headers: headers).0
    }

    func post<ReceivedObject: Decodable>(_ object: some Encodable, to url: URL, headers: [String: String], context: [CodingUserInfoKey: Sendable]?) async throws -> ReceivedObject {
        try await process(.post, object: object, url: url, headers: headers, context: context)
    }

    // MARK: MultipartForm

    private func payload(for form: MultipartForm) -> Payload {
        Payload(
            data: form.data,
            contentType: ContentType.multipartForm(MultipartForm.boundary),
            typeName: "\(MultipartForm.self)",
            summary: form.summary
        )
    }

    func post(_ form: MultipartForm, to url: URL, headers: [String: String] = [:]) async throws -> Data? {
        let payload = payload(for: form)

        let request = ClientRequest(
            url: url,
            method: .post,
            payload: payload,
            accept: .json,
            headers: headers
        )

        return try await sendRequest(request).0
    }

    func post<ReceivedObject: Decodable>(_ form: MultipartForm, to url: URL, headers: [String: String] = [:], context: [CodingUserInfoKey: Sendable]? = nil) async throws -> ReceivedObject {

        let payload = payload(for: form)

        let request = ClientRequest(
            url: url,
            method: .post,
            payload: payload,
            accept: .json,
            headers: headers
        )

        return try await sendRequestAndDecode(request, context: context)
    }

    // MARK: URLEncodedForm

    private func payload(for form: URLEncodedForm) -> Payload {
        Payload(
            data: form.data,
            contentType: ContentType.urlEncodedForm,
            typeName: "\(URLEncodedForm.self)",
            summary: form.summary
        )
    }

    func post(_ form: URLEncodedForm, to url: URL, headers: [String: String] = [:]) async throws -> Data? {
        let payload = payload(for: form)

        let request = ClientRequest(
            url: url,
            method: .post,
            payload: payload,
            accept: .binary,
            headers: headers
        )

        return try await sendRequest(request).0
    }

    func post<ReceivedObject: Decodable>(_ form: URLEncodedForm, to url: URL, headers: [String: String] = [:], context: [CodingUserInfoKey: Sendable]? = nil) async throws -> ReceivedObject {

        let payload = payload(for: form)

        let request = ClientRequest(
            url: url,
            method: .post,
            payload: payload,
            accept: .json,
            headers: headers
        )

        return try await sendRequestAndDecode(request, context: context)
    }
}

// MARK: - PUT

public extension HTTPClient {

    func put(_ url: URL, headers: [String: String] = [:]) async throws -> Data? {
        try await process(.put, url: url, headers: headers).0
    }

    func put<ReceivedObject: Decodable>(_ data: Data, to url: URL, headers: [String: String] = [:], context: [CodingUserInfoKey: Sendable]? = nil) async throws -> ReceivedObject {
        try await process(.put, data: data, url: url, headers: headers, context: context)
    }

    func put(_ object: some Encodable, to url: URL, headers: [String: String] = [:]) async throws -> Data? {
        try await process(.put, object: object, url: url, headers: headers).0
    }

    func put<ReceivedObject: Decodable>(_ object: some Encodable, to url: URL, headers: [String: String], context: [CodingUserInfoKey: Sendable]?) async throws -> ReceivedObject {
        try await process(.delete, object: object, url: url, headers: headers, context: context)
    }
}

// MARK: - DELETE

public extension HTTPClient {

    func delete(_ url: URL, headers: [String: String] = [:]) async throws -> Data? {
        try await process(.delete, url: url, headers: headers).0
    }

    func delete<ReceivedObject: Decodable>(_ data: Data, to url: URL, headers: [String: String] = [:], context: [CodingUserInfoKey: Sendable]? = nil) async throws -> ReceivedObject {
        try await process(.delete, data: data, url: url, headers: headers, context: context)
    }

    func delete(_ object: some Encodable, to url: URL, headers: [String: String] = [:]) async throws -> Data? {
        try await process(.delete, object: object, url: url, headers: headers).0
    }

    func delete<ReceivedObject: Decodable>(_ object: some Encodable, to url: URL, headers: [String: String], context: [CodingUserInfoKey: Sendable]?) async throws -> ReceivedObject {
        try await process(.delete, object: object, url: url, headers: headers, context: context)
    }
}

// MARK: - Private Implementation

extension HTTPClient {

    private func process(_ method: Method, url: URL, headers: [String: String] = [:]) async throws -> (
        Data?, HTTPURLResponse) {

        let request = ClientRequest(
            url: url,
            method: method,
            payload: .none,
            accept: .binary,
            headers: headers
        )

        return try await sendRequest(request)
    }

    private func process<ReceivedObject: Decodable>(_ method: Method, data: Data?, url: URL, headers: [String: String] = [:], context: [CodingUserInfoKey: Sendable]? = nil) async throws -> ReceivedObject {

        let payload =
            if let data {
                Payload(
                    data: data,
                    contentType: .binary,
                    typeName: "\(Data.self)",
                    summary: data.count.formatted(.byteCount(style: .memory))
                )
            } else {
                Payload.none
            }

        let request = ClientRequest(
            url: url,
            method: method,
            payload: payload,
            accept: .json,
            headers: headers
        )

        return try await sendRequestAndDecode(request, context: context)
    }

    private func process<SentObject: Encodable>(_ method: Method, object: SentObject, url: URL, headers: [String: String] = [:]) async throws -> (Data?, HTTPURLResponse) {

        let encodedObject = try jsonCoder.encode(object, context: nil)

        let payload = Payload(
            data: encodedObject,
            contentType: .json,
            typeName: "\(SentObject.self)",
            summary: ((object as? Summarizable)?.summary) ?? encodedObject.summary
        )

        let request = ClientRequest(url: url, method: method, payload: payload, accept: .binary)

        return try await sendRequest(request)
    }

    private func process<SentObject: Encodable, ReceivedObject: Decodable>(_ method: Method, object: SentObject, url: URL, headers: [String: String], context: [CodingUserInfoKey: Sendable]?) async throws -> ReceivedObject {

        let encodedObject = try jsonCoder.encode(object, context: context)

        let payload = Payload(
            data: encodedObject,
            contentType: .json,
            typeName: "\(SentObject.self)",
            summary: ((object as? Summarizable)?.summary) ?? encodedObject.summary
        )

        let request = ClientRequest(url: url, method: .put, payload: payload, accept: .json)

        return try await sendRequestAndDecode(request, context: context)
    }

    private func sendRequestAndDecode<T: Decodable>(_ request: ClientRequest, context: [CodingUserInfoKey: any Sendable]?) async throws -> T {

        let (data, _) = try await sendRequest(request)

        guard let data else {
            throw JSONCoder.Error(description: "HTTP request returned no data.", process: .decode)
        }

        return try jsonCoder.decode(data, context: context)
    }

    fileprivate final class RequestCounter {
        private var value: Int = 0
        private let queue = DispatchQueue(label: "HTTPRequest.RequestCounter")

        func increment() -> Int {
            queue.sync {
                if value == .max - 1 {
                    value = 0
                } else {
                    value += 1
                }
                return value
            }
        }

        func get() -> Int {
            queue.sync { value }
        }
    }
}
