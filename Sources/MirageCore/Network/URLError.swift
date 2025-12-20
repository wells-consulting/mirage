//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct URLError: MirageErrorProtocol {

    public let refcode: String
    public var summary: String { "Failed to build URL." }
    public let summaryFooter: String?
    public let details: String?
    public let title: String? = "URL Error"
    public let urlString: String?
    public let urlComponents: URLComponents?
    public let errors: [any Error]?
    public let userInfo: [String: any Sendable]?

    init(
        refcode: String,
        summaryFooter: String?,
        details: String? = nil,
        urlString: String? = nil,
        urlComponents: URLComponents? = nil,
        errors: [any Error]? = nil,
        userInfo: [String: any Sendable]? = nil
    ) {
        self.refcode = refcode
        self.summaryFooter = summaryFooter
        self.details = details
        self.errors = errors

        var implicitUserInfo: [String: any Sendable] = userInfo ?? [:]

        self.urlString = urlString
        implicitUserInfo["url_string"] = urlString

        self.urlComponents = urlComponents
        implicitUserInfo["url_components"] = urlComponents

        self.userInfo = implicitUserInfo
    }

    // MARK: - Factory Methods

    static func urlMissingScheme(
        refcode: String,
        urlString: String,
        urlComponents: URLComponents?
    ) -> Self {
        .init(
            refcode: refcode,
            summaryFooter: "String is not in a valid URL format.",
            details: "Cannot create a URL from '\(urlString)' because it is missing a scheme.",
            urlString: urlString,
            urlComponents: urlComponents
        )
    }

    static func urlMissingHost(
        refcode: String,
        urlString: String,
        urlComponents: URLComponents?
    ) -> Self {
        .init(
            refcode: refcode,
            summaryFooter: nil,
            details: "Cannot create a URL from '\(urlString)' because it is missing a host.",
            urlString: urlString,
            urlComponents: urlComponents
        )
    }

    static func urlInvalid(
        refcode: String,
        urlString: String,
        urlComponents: URLComponents?
    ) -> Self {
        .init(
            refcode: refcode,
            summaryFooter: nil,
            details: "Cannot create a URL from '\(urlString)'.",
            urlString: urlString,
            urlComponents: urlComponents
        )
    }
}
