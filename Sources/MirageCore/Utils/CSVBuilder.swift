//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public final class CSVBuilder {

    private let headerRow: String
    private var rows: [String] = []

    public init(headerRow: String) {
        self.headerRow = headerRow
    }

    public func addRow(_ row: String?) {
        guard let row else { return }
        rows.append(row)
    }

    public var text: String {
        rows.joined(separator: "\n")
    }

    public func saveToDownloadsFolder(filename: String) throws {
        do {
            let url = try FileManager.default.url(for: .downloadsDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(filename)
            try save(to: url)
        } catch {
            throw Self.Error(description: error.localizedDescription, title: "Save CSV Failed", underlyingError: error, userInfo: ["url": nil, "filename": filename])
        }
    }

    public func save(to url: URL) throws {
        rows.insert(headerRow, at: 0)

        let data = Data(text.utf8)

        do {
            try data.write(to: url, options: [.atomic, .completeFileProtection])
        } catch {
            throw Self.Error(description: error.localizedDescription, title: "Save CSV Failed", underlyingError: error, userInfo: ["url": url, "data_size": data.count.formatted(.byteCount(style: .file))])
        }
    }

    // MARK: - Error

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

        init(description: String, title: String? = nil, underlyingError: (any Swift.Error)? = nil, userInfo: [String: any Sendable]? = nil) {
            self.description = description
            self.title = title ?? "CSV Error"
            self.underlyingError = underlyingError
            self.userInfo = userInfo
        }
    }
}
