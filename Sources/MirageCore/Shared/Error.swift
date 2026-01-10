//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public enum MirageCore {

    /// General purpose Mirage error.
    public struct Error: MirageError {

        /// Localized error description
        public let description: String

        /// LocalizedError conformance
        public var errorDescription: String? { description }

        /// Localized title text
        public let title: String?

        /// Wrapped error
        public let underlyingError: (any Swift.Error)?

        /// Error-specific context
        public let userInfo: [String: any Sendable]?

        /// - Parameters:
        ///     - description: Text appropriate for a user-facing alert message
        ///     - title: Title text appropriate for a user-facing dialog title
        ///     - underlyingError: UnderlyingError wrapped error
        ///     - context: Error-specific context
        public init(description: String, title: String? = nil, underlyingError: (any Swift.Error)? = nil, userInfo: [String: any Sendable]? = nil) {
            self.description = description
            self.title = title
            self.underlyingError = underlyingError
            self.userInfo = userInfo
        }
    }
}
