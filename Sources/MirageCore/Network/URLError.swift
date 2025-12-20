//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct URLError: MirageError {

    // MARK: - MirageError conformance

    public let referenceCode: String?
    public let alertTitle: String?
    public let clarification: String?
    public let details: String?
    public let recoverySuggestion: String?
    public let underlyingErrors: [any Error]?
    public let userInfo: [String: any Sendable]?

    // MARK: - Error specific

    public let urlString: String?
    public let urlComponents: URLComponents?

    init(
        referenceCode: String?,
        clarification: String? = nil,
        details: String? = nil,
        recoverySuggestion: String? = nil,
        urlString: String? = nil,
        urlComponents: URLComponents? = nil,
        underlyingErrors: [any Error]? = nil,
        userInfo: [String: any Sendable]? = nil
    ) {

        self.referenceCode = referenceCode
        self.alertTitle = "URL Error"
        self.clarification = clarification ?? "Failed to build URL."
        self.details = details
        self.recoverySuggestion = recoverySuggestion
        self.underlyingErrors = underlyingErrors
        self.userInfo = userInfo

        self.urlString = urlString
        self.urlComponents = urlComponents
    }

    // MARK: - Factory Methods

    static func urlMissingScheme(
        referenceCode: String,
        urlString: String,
        urlComponents: URLComponents?,
    ) -> Self {

        .init(
            referenceCode: referenceCode,
            clarification: "Invalid URL format.",
            details: "Cannot create a URL from '\(urlString)' because it is missing a scheme.",
            urlString: urlString,
            urlComponents: urlComponents
        )
    }

    static func urlMissingHost(
        referenceCode: String,
        urlString: String,
        urlComponents: URLComponents?
    ) -> Self {

        .init(
            referenceCode: referenceCode,
            clarification: "Invalid URL format.",
            details: "Cannot create a URL from '\(urlString)' because it is missing a host.",
            urlString: urlString,
            urlComponents: urlComponents
        )
    }

    static func urlInvalid(
        referenceCode: String,
        urlString: String,
        urlComponents: URLComponents?
    ) -> Self {

        .init(
            referenceCode: referenceCode,
            clarification: "Invalid URL format.",
            details: "Cannot create a URL from '\(urlString)'.",
            urlString: urlString,
            urlComponents: urlComponents
        )
    }
}
