//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// Message text with additional context.
public struct Message: Hashable, Codable, Sendable, Titled {

    /// Message text
    public let text: String

    /// Message title; typically used in UI for dialogs or alerts
    public let title: String?

    /// Messsage severity; typically used to style text in UI
    public let severity: Severity

    public func hash(into hasher: inout Hasher) {
        hasher.combine(text)
        if let title { hasher.combine(title) }
        hasher.combine(severity.rawValue)
    }

    /// Helper method to create an informational messsage.
    ///
    /// - Parameters:
    ///     - text: Message text
    ///     - title: Message title
    ///
    /// - Returns:
    ///     Informational message
    public static func info(_ text: String, title: String? = nil) -> Self {
        .init(text: text, title: title, severity: .info)
    }

    /// Helper method to create a warning messsage.
    ///
    /// - Parameters:
    ///     - text: Message text
    ///     - title: Message title
    ///
    /// - Returns:
    ///     Warning message
    public static func warning(_ text: String, title: String? = nil) -> Self {
        .init(text: text, title: title, severity: .warning)
    }

    /// Helper method to create an error messsage.
    ///
    /// - Parameters:
    ///     - text: Message text
    ///     - title: Message title
    ///
    /// - Returns:
    ///     Error message
    public static func error(_ text: String, title: String? = nil) -> Self {
        .init(text: text, title: title, severity: .error)
    }

    /// Helper method to create an error messsage.
    ///
    /// Title is inferred as follows: if title is supplied at call site, that
    /// title is used. If the title is not supplied and the error has a title,
    /// that title is used. Otherwise, the message is created without a title.
    ///
    /// - Parameters:
    ///     - text: Message text
    ///     - title: Message title
    ///
    /// - Returns:
    ///     Informational message
    public static func error(_ error: Error, title: String? = nil) -> Self {
        let text = error.localizedDescription
        let title = title ?? ((error as? Titled)?.title)
        return .init(text: text, title: title, severity: .error)
    }

    /// Message severity
    public enum Severity: Int, Equatable, Comparable, Codable, Sendable, Titled {
        case info
        case warning
        case error

        public var title: String? {
            switch self {
            case .info:
                "Info"
            case .warning:
                "Warning"
            case .error:
                "Error"
            }
        }

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}
