//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct HTTPError: MirageErrorProtocol {

    public let refcode: String

    public var summary: String {
        if let statusCode {
            "HTTP request failed with status \(statusCode.description)."
        } else {
            "HTTP request failed."
        }
    }

    public let summaryFooter: String?
    public let details: String?
    public let title: String? = "Mirage HTTP Error"
    public var errorDescription: String? { "" /* summary */ }
    public let urlRequest: URLRequest?
    public let httpURLResponse: HTTPURLResponse?
    public let responseTimeRange: Range<Date>?

    public var statusCode: HTTPClient.StatusCode? {
        if let statusCodeRawValue = httpURLResponse?.statusCode {
            HTTPClient.StatusCode(rawValue: statusCodeRawValue)
        } else {
            nil
        }
    }

    public let responseData: Data?

    public func value(forHeader name: String) -> String? {
        httpURLResponse?.value(forHTTPHeaderField: name)
    }

    public let errors: [any Error]?

    public let userInfo: [String: any Sendable]?

    init(
        refcode: String,
        summaryFooter: String?,
        details: String?,
        urlRequest: URLRequest? = nil,
        httpURLResponse: HTTPURLResponse? = nil,
        responseData: Data? = nil,
        responseTimeRange: Range<Date>? = nil,
        errors: [any Error]? = nil,
        userInfo: [String: any Sendable]? = nil
    ) {
        self.refcode = refcode
        self.summaryFooter = summaryFooter
        self.details = details
        self.urlRequest = urlRequest
        self.httpURLResponse = httpURLResponse
        self.responseData = responseData
        self.responseTimeRange = responseTimeRange
        self.errors = errors
        self.userInfo = userInfo
    }

    init(
        refcode: String,
        summaryFooter: String?,
        clientRequest: HTTPClient.ClientRequest,
        httpURLResponse: HTTPURLResponse?,
        responseData: Data?,
        responseTimeRange: Range<Date>? = nil,
        errors: [any Error]? = nil,
        userInfo: [String: any Sendable]? = nil
    ) {
        self.refcode = refcode
        self.summaryFooter = summaryFooter
        self.urlRequest = clientRequest.urlRequest
        self.httpURLResponse = httpURLResponse
        self.responseData = responseData
        self.responseTimeRange = responseTimeRange
        self.errors = errors
        self.userInfo = userInfo

        var lines: [String] = []

        if let methodRawValue = clientRequest.urlRequest.httpMethod, let method = HTTPClient.Method(rawValue: methodRawValue) {
            if let statusCodeRawValue = httpURLResponse?.statusCode,
               let statusCode = HTTPClient.StatusCode(rawValue: statusCodeRawValue)
            {
                lines.append("HTTP \(method.rawValue) failed with \(statusCode.description).")
            } else {
                lines.append("HTTP \(method.rawValue) failed.")
            }
        } else {
            lines.append("HTTP request failed.")
        }

        if let responseData {
            lines.append("Received " + responseData.count.formatted(.byteCount(style: .memory)) + " bytes.")
        }

        if let responseTimeRange {
            lines.append("Completed in \(responseTimeRange.debugDurationString).")
        }

        self.details = lines.joined(separator: "\n")
    }

    // MARK: - Factory Methods

    static func missingURL(refcode: String) -> MirageError {
        .http(.init(
            refcode: refcode,
            summaryFooter: "Network request failed.",
            details: "The network request couldn't be made because there is no URL.",
        ))
    }
}
