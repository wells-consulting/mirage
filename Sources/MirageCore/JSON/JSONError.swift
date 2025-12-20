//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct JSONError: MirageErrorProtocol {

    public enum Process: Sendable {
        case encode
        case decode
    }

    /// Reference code for developer
    public let refcode: String

    /// Localizable summary
    public var summary: String {
        switch process {
        case .decode:
            "JSON decoding failed."
        case .encode:
            "JSON encoding failed."
        }
    }

    public let summaryFooter: String?

    /// Message details that may contain developer-suitable
    public let details: String?

    /// Localizable title
    public let title: String? = "JSON Error"

    /// Error source: encoding or decoding
    public let process: Process

    /// JSON text
    public let jsonText: String?

    /// Wrapped errors
    public let errors: [any Error]?

    /// Error-specific context
    public let userInfo: [String: any Sendable]?

    public init(
        refcode: String,
        process: Process,
        summaryFooter: String?,
        details: String? = nil,
        data: Data? = nil,
        errors: [any Error]? = nil,
        userInfo: [String: any Sendable]? = nil
    ) {
        self.refcode = refcode
        self.summaryFooter = summaryFooter

        self.process = process
        switch process {
        case .encode:
            if let details {
                self.details = details
            } else {
                self.details = "Could not encode value."
            }
        case .decode:
            if let details {
                self.details = details
            } else {
                self.details = "Could not decode value."
            }
        }

        var implicitUserInfo: [String: any Sendable] = userInfo ?? [:]

        if let data {
            implicitUserInfo["data_size"] = data.count.formatted(.byteCount(style: .memory))
            if let jsonText = String(data: data, encoding: .utf8) {
                self.jsonText = jsonText
            } else {
                self.jsonText = nil
            }
        } else {
            self.jsonText = nil
        }

        self.errors = errors
        self.userInfo = implicitUserInfo
    }
}
