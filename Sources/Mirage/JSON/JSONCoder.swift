//
// Copyright 2025 Wells Consulting.
// This file is part of Mirage and is released under the MIT License.
//

import Foundation

public struct JSONCoder: Sendable {

    private let logger = PlatformLogger(category: "JSONCoder")

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public static let shared = JSONCoder()

    // MARK: - Initializer

    public struct Configuration: Sendable {

        let keyEncodingStrategy: JSONEncoder.KeyEncodingStrategy = .useDefaultKeys
        let dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .iso8601
        let outputFormatting: JSONEncoder.OutputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        let keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys
        let dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .iso8601
        let allowsJSON5: Bool = true

        public static let `default` = Configuration()
    }

    public init(configuration: Configuration = .default) {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = configuration.keyEncodingStrategy
        encoder.dateEncodingStrategy = configuration.dateEncodingStrategy
        encoder.outputFormatting = configuration.outputFormatting
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = configuration.keyDecodingStrategy
        decoder.dateDecodingStrategy = configuration.dateDecodingStrategy
        decoder.allowsJSON5 = configuration.allowsJSON5
        self.decoder = decoder
    }

    // MARK: - Encode

    /// Encode value to raw data.
    ///
    /// - Parameters
    ///     - value: Value to encode
    ///     - context: Additional coding context passed to encoders
    ///
    /// - Returns
    ///     - Raw encoded data
    ///
    /// - Throws
    ///     - JSONError if the value could not be encoded.
    public func encode<T: Encodable>(_ value: T, userInfo: [CodingUserInfoKey: Sendable]? = nil) throws -> Data {
        var message = ""
        var underlyingError: (any Swift.Error)?

        do {
            if let userInfo {
                for (key, value) in userInfo {
                    encoder.userInfo[key] = value
                }
            }

            defer {
                if let userInfo {
                    for (key, _) in userInfo {
                        encoder.userInfo.removeValue(forKey: key)
                    }
                }
            }

            return try encoder.encode(value)
        } catch let EncodingError.invalidValue(key, context) {
            underlyingError = context.underlyingError
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            message = "\(T.self): key '\(key)' is missing for path '\(path)'"
        } catch {
            underlyingError = error
            message = "\(T.self): \(error)"
        }

        logger.error(message)

        let errorUserInfo: [String: any Sendable]? = if let userInfo {
            Dictionary(uniqueKeysWithValues: userInfo.map { ($0.key.rawValue, $0.value) })
        } else {
            nil
        }

        throw Self.Error(description: message, process: .encode, underlyingError: underlyingError, userInfo: errorUserInfo)
    }

    // MARK: - Decode

    /// Decode value from raw data.
    ///
    /// - Parameters
    ///     - data: Raw data
    ///     - context: Additional coding context passed to decoders
    ///
    /// - Returns
    ///     - Typed value
    ///
    /// - Throws
    ///     - JSONError if the value could not be decoded.
    public func decode<T: Decodable>(_ data: Data?, userInfo: [CodingUserInfoKey: Sendable]? = nil) throws -> T {
        guard let data else {
            let message = "\(T.self) could not be created: no data"
            logger.error(message)
            throw Self.Error(description: message, process: .decode, data: nil)
        }

        var message = ""
        var underlyingError: (any Swift.Error)?

        do {
            if let userInfo {
                for (key, value) in userInfo {
                    decoder.userInfo[key] = value
                }
            }

            defer {
                if let userInfo {
                    for (key, _) in userInfo {
                        decoder.userInfo.removeValue(forKey: key)
                    }
                }
            }

            let object: T = try decoder.decode(T.self, from: data)

            return object
        } catch let DecodingError.dataCorrupted(context) {
            underlyingError = context.underlyingError
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            message = "\(T.self): data corrupted. Issue decoding '\(path)'\n\(context.debugDescription)"
        } catch let DecodingError.keyNotFound(key, context) {
            underlyingError = context.underlyingError
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            if path.isEmpty {
                message = "\(T.self): key '\(key.stringValue)' missing (KeyNotFound)\n\(context.debugDescription)"
            } else {
                message = "\(T.self): key '\(key.stringValue)' missing at '\(path)' (KeyNotFound)\n\(context.debugDescription)"
            }
        } catch let DecodingError.valueNotFound(type, context) {
            underlyingError = context.underlyingError
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            if path.isEmpty {
                message = "\(T.self): value \(type) not found (ValueNotFound)\n\(context.debugDescription)"
            } else {
                message = "\(T.self): value \(type) not found at '\(path)' (ValueNotFound)\n\(context.debugDescription)"
            }
        } catch let DecodingError.typeMismatch(type, context) {
            underlyingError = context.underlyingError
            let path = context.codingPath.map(\.stringValue).joined(separator: ".")
            if path.isEmpty {
                message = "\(T.self): \(type) not found (TypeMismatch)\n\(context.debugDescription)"
            } else {
                message = "\(T.self): \(type) not found at '\(path)' (TypeMismatch)\n\(context.debugDescription)"
            }
        } catch {
            underlyingError = error
            message = "\(T.self): \(error)"
        }

        logger.error(message)

        let errorUserInfo: [String: any Sendable]? = if let userInfo {
            Dictionary(uniqueKeysWithValues: userInfo.map { ($0.key.rawValue, $0.value) })
        } else {
            nil
        }

        throw Self.Error(description: message, process: .decode, data: data, underlyingError: underlyingError, userInfo: errorUserInfo)
    }

    // MARK: - Stringify

    /// Create JSON string from a value.
    ///
    /// - Parameters
    ///     - value: Value to convert
    ///
    /// - Returns
    ///     - JSON string if it can be created, nil otherwise
    public func stringify(_ value: some Encodable) -> String? {
        do {
            let data = try encoder.encode(value)
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }

    // MARK: - Error

    public struct Error: MirageError {

        public enum Process: Sendable {
            case encode
            case decode
        }

        /// Localized title text
        public let title: String?

        /// Localized message text
        public let description: String

        /// LocalizedError conformance
        public var errorDescription: String? { description }

        /// Error source: encoding or decoding
        public let process: Process

        /// JSON text
        public let jsonText: String?

        /// Wrapped error
        public let underlyingError: (any Swift.Error)?

        /// Error-specific context
        public let userInfo: [String: any Sendable]?

        init(description: String, title: String? = nil, process: Process, data: Data? = nil, underlyingError: (any Swift.Error)? = nil, userInfo: [String: any Sendable]? = nil) {
            switch process {
            case .encode:
                self.description = "JSON Encode Error: \(description)"
            case .decode:
                self.description = "JSON Decode Error: \(description)"
            }

            self.title = title ?? "JSON Error"
            self.process = process

            var implicitUserInfo: [String: any Sendable] = userInfo ?? [:]

            if let data {
                implicitUserInfo["data_size"] = data.count.formatted(.byteCount(style: .memory))
                if let jsonText = String(data: data, encoding: .utf8) {
                    implicitUserInfo["json"] = jsonText
                    self.jsonText = jsonText
                } else {
                    self.jsonText = nil
                }
            } else {
                self.jsonText = nil
            }

            self.underlyingError = underlyingError
            self.userInfo = implicitUserInfo
        }
    }
}
