//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct JSONError: MirageError {

    public enum Process: Sendable {
        case encode
        case decode
    }

    // MirageError conformance

    public let message: String
    public let referenceCode: String?
    public let alertTitle: String?
    public let clarification: String?
    public let details: String?
    public let recoverySuggestion: String?
    public let underlyingErrors: [any Error]?
    public let userInfo: [String: any Sendable]?

    // Error specific

    public let process: Process
    public let jsonText: String?

    public init(
        process: Process,
        referenceCode: String?,
        alertTitle: String? = nil,
        clarification: String? = nil,
        details: String? = nil,
        recoverySuggestion: String? = nil,
        underlyingErrors: [any Error]? = nil,
        userInfo: [String: any Sendable]? = nil,
        data: Data? = nil,
    ) {

        self.message =
            switch process {
            case .decode:
                "JSON decoding failed."
            case .encode:
                "JSON encoding failed."
            }
        self.referenceCode = referenceCode
        self.alertTitle = alertTitle ?? "Mirage JSON Error"
        self.clarification = clarification
        self.details =
            if let details {
                details
            } else {
                switch process {
                case .encode:
                    "Could not encode value."
                case .decode:
                    "Could not decode value."
                }
        }
        self.recoverySuggestion = recoverySuggestion
        self.underlyingErrors = underlyingErrors
        self.userInfo = userInfo

        self.process = process
        self.jsonText =
            if let data {
                String(data: data, encoding: .utf8)
            } else {
                nil
            }
    }
}
