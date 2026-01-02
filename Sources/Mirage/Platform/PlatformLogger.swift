//
// Copyright 2025 Wells Consulting.
// This file is part of Mirage and is released under the MIT License.
//

import Foundation

/// Platform agnostic OSLogger logging.
///
/// Linux implementations cannot, at this moment, import "os" that exposes
/// the new OS.Logger.
///
/// Log has two simple goals: (1) make logging a small bit more ergonomic
/// so that strings (not string literals) can be passed as log messages and
/// (2) provide a basic, print-based, logger for Linux.
///
/// Log should be a drop-in replacement for os.Logger.
///

#if canImport(os)

import os

public struct PlatformLogger: Sendable {

    private let logger: os.Logger

    init(category: String) {
        self.logger = os.Logger(subsystem: "Mirage", category: category)
    }

    public init(subsystem: String, category: String) {
        self.logger = os.Logger(subsystem: subsystem, category: category)
    }

    public func debug(_ message: String, file: StaticString = #fileID, line: UInt = #line) {
        logger.debug("\(message) [\(file):\(line)]")
    }

    public func info(_ message: String, file: StaticString = #fileID, line: UInt = #line) {
        logger.info("\(message) [\(file):\(line)]")
    }

    public func warning(_ message: String, file: StaticString = #fileID, line: UInt = #line) {
        logger.warning("\(message) [\(file):\(line)]")
    }

    public func error(_ message: String, task: String? = nil, file: StaticString = #fileID, line: UInt = #line) {
        logger.error("\(message) [\(file):\(line)]")
    }
}

public extension PlatformLogger {
    func error(_ error: any Error, task: String? = nil, file: StaticString = #fileID, line: UInt = #line) {
        let message = if let task {
            "\(task) failed with error: \(error)"
        } else {
            "\(error)"
        }

        logger.error("\(message) [\(file):\(line)]")
    }
}

#else

public struct PlatformLogger: Sendable {

    private let subsystem: String
    private let category: String

    init(subsystem: String = "Mirage", category: String) {
        self.subsystem = subsystem
        self.category = category
    }

    public func debug(_ message: String, file: StaticString = #fileID, line: UInt = #line) {
        print("\(subsystem).\(category) | DEBUG \(message) [\(file):\(line)]")
    }

    public func info(_ message: String, file: StaticString = #fileID, line: UInt = #line) {
        print("\(subsystem).\(category) | INFO \(message) [\(file):\(line)]")
    }

    public func warning(_ message: String, file: StaticString = #fileID, line: UInt = #line) {
        print("\(subsystem).\(category) | WARNING \(message) [\(file):\(line)]")
    }

    public func error(_ message: String, file: StaticString = #fileID, line: UInt = #line) {
        print("\(subsystem).\(category) | ERROR \(message) [\(file):\(line)]")
    }

    public func error(_ error: any Error, task: String? = nil, file: StaticString = #fileID, line: UInt = #line) {
        let message = if let task {
            "\(task) failed with error: \(error)"
        } else {
            "\(error)"
        }

        print("\(subsystem).\(category) | ERROR \(message) [\(file):\(line)]")
    }
}

#endif
