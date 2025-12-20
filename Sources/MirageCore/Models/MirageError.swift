//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public enum MirageError: MirageErrorProtocol {

    case csv(CSVError)
    case http(HTTPError)
    case json(JSONError)
    case system(Error)
    case app(Error)

    public var errorDescription: String? { summary }

    public var refcode: String {
        switch self {
        case let .csv(error):
            error.refcode
        case let .http(error):
            error.refcode
        case let .json(error):
            error.refcode
        case let .system(error):
            (error as? RefcodeProviding)?.refcode ?? "SYS"
        case let .app(error):
            (error as? RefcodeProviding)?.refcode ?? "APP"
        }
    }

    public var summary: String {
        "Error \(refcode)\nThe details below might be helpful to diagnose the problem."
    }

    public var summaryFooter: String? {
        switch self {
        case let .csv(error):
            error.summaryFooter
        case let .http(error):
            error.summaryFooter
        case let .json(error):
            error.summaryFooter
        case let .system(error):
            (error as? SummaryFooterProviding)?.summaryFooter ?? error.localizedDescription
        case let .app(error):
            (error as? SummaryFooterProviding)?.summaryFooter ?? error.localizedDescription
        }
    }

    public var title: String? {
        switch self {
        case let .csv(error):
            error.title ?? "Mirage Error"
        case let .http(error):
            error.title ?? "Mirage Error"
        case let .json(error):
            error.title ?? "Mirage Error"
        case let .system(error):
            "\(error.self)"
        case let .app(error):
            (error as? TitleProviding)?.title
        }
    }

    public var details: String? {
        switch self {
        case let .csv(error):
            error.details
        case let .http(error):
            error.details
        case let .json(error):
            error.details
        case let .system(error):
            (error as? DetailsProviding)?.details ?? "\(error)"
        case let .app(error):
            (error as? DetailsProviding)?.details ?? "\(error)"
        }
    }

    public var errors: [any Error]? {
        switch self {
        case let .csv(error):
            error.errors
        case let .http(error):
            error.errors
        case let .json(error):
            error.errors
        case let .system(error):
            (error as NSError).underlyingErrors
        case let .app(error):
            (error as NSError).underlyingErrors
        }
    }

    public var userInfo: [String: any Sendable]? {
        switch self {
        case let .csv(error):
            return error.userInfo

        case let .http(error):
            return error.userInfo

        case let .json(error):
            return error.userInfo

        case .system:
            return nil

        case let .app(error):
            var values = [String: any Sendable]()

            for (key, value) in (error as NSError).userInfo {
                let sendableValue: any Sendable = switch value {
                case let v as String: v
                case let v as Int: v
                case let v as Double: v
                case let v as Float: v
                case let v as Bool: v
                case let v as Date: v
                case let v as URL: v
                case let v as Data: v
                case let v as [String: Any]: String(describing: v)
                case let v as [Any]: String(describing: v)
                default: String(describing: value)
                }
                values[key] = sendableValue
            }

            return values.isEmpty ? nil : values
        }
    }
}

// MARK: - Protocol

public protocol MirageErrorProtocol: LocalizedError & RefcodeProviding & SummaryProviding & SummaryFooterProviding & DetailsProviding & TitleProviding & UserInfoProviding {

    var errors: [any Error]? { get }
    var verboseDebugDescription: String? { get }
}

public extension MirageErrorProtocol {
    var verboseDebugDescription: String? {
        var lines = [String]()

        if let details {
            lines.append("Details: \(details)\n")
        }

        if let userInfo, !userInfo.isEmpty {
            lines.append("User Info: " + String(describing: userInfo) + "\n")
        }

        if let errors, !errors.isEmpty {
            for error in errors {
                if
                    let mirageError = error as? MirageErrorProtocol,
                    let verboseDescription = mirageError.verboseDebugDescription
                {
                    lines.append("Underlying Error: " + verboseDescription)
                } else {
                    lines.append("Underlying Error: " + error.localizedDescription)
                }
            }
        }

        // If error bridges to NSError, add additional info.
        let nsError = self as NSError
        if nsError.domain != "NSCocoaErrorDomain" || nsError.code != 0 {
            lines.append("\nDomain: \(nsError.domain), Code: \(nsError.code), User Info: \(String(describing: nsError.userInfo))")
        }

        return lines.joined(separator: "\n")
    }
}
