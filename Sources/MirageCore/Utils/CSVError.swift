//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

public struct CSVError: MirageErrorProtocol {

    public let refcode: String
    public var summary: String { "Could not save CSV file." }
    public let summaryFooter: String?
    public let details: String?
    public let title: String? = "CSV Error"
    public let errors: [any Error]?
    public let userInfo: [String: any Sendable]?

    init(
        refcode: String,
        summaryFooter: String?,
        details: String? = nil,
        errors: [any Error]? = nil,
        userInfo: [String: any Sendable]? = nil
    ) {
        self.refcode = refcode
        self.summaryFooter = summaryFooter
        self.details = details
        self.errors = errors
        self.userInfo = userInfo
    }

    static func saveTo(_ url: URL, data: Data, error: Error) -> Self {
        .init(
            refcode: "DAFC",
            summaryFooter: nil,
            details: "Failed to save \(data.count.formatted(.byteCount(style: .file))) CSV file to '\(url.absoluteString)'.",
            errors: [error],
            userInfo: ["url": url]
        )
    }

    static func saveToDownloadsFolder(filename: String, data: Data, error: Error) -> Self {
        .init(
            refcode: "4XGP",
            summaryFooter: nil,
            details: "Failed to save \(data.count.formatted(.byteCount(style: .file))) CSV file '\(filename)' to the downloads folder.",
            errors: [error],
            userInfo: ["filename": filename]
        )
    }
}
