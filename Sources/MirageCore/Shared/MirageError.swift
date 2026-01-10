//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public protocol MirageError: LocalizedError, CustomStringConvertible, CustomDebugStringConvertible, Titled, Sendable {
    var underlyingError: (any Swift.Error)? { get }
    var userInfo: [String: any Sendable]? { get }
}

public extension MirageError {

    var debugDescription: String {
        var string = description

        if let underlyingError {
            string.append("\nUnderyling Error: " + Self.describe(underlyingError))
        }

        if let userInfo, !userInfo.isEmpty {
            string.append("\nUserInfo: " + String(describing: userInfo))
        }

        return string
    }

    var message: Message { Message(text: description, title: title, severity: .error) }

    private static func describe(_ error: any Swift.Error) -> String {
        var result = String(describing: self)

        // If error bridges to NSError, add additional info.
        let nsError = error as NSError
        if nsError.domain != "NSCocoaErrorDomain" || nsError.code != 0 {
            result += " (domain: \(nsError.domain), code: \(nsError.code))"
            if !nsError.userInfo.isEmpty {
                result += ", userInfo: \(nsError.userInfo)"
            }
        }

        return result
    }
}
