//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import MirageCore
import SwiftUI

public struct ErrorView: View {

    private let title: String
    private let summary: String
    private let summaryFooter: String?
    private let details: String?
    private let verboseDebugDescription: String?
    private let buttonText: String
    private let onButtonTapped: () -> Void

    public init(error: any Error, buttonText: String = "Retry", onButtonTapped: @escaping () -> Void) {
        self.title = (error as? (any TitleProviding))?.title ?? "Error"
        self.summary = (error as? SummaryProviding)?.summary ?? error.localizedDescription
        self.summaryFooter = (error as? SummaryFooterProviding)?.summaryFooter
        self.details = (error as? (any DetailsProviding))?.details
        self.verboseDebugDescription = (error as? MirageErrorProtocol)?.verboseDebugDescription
        self.buttonText = buttonText
        self.onButtonTapped = onButtonTapped
    }

    public init(message: Message, buttonText: String = "Retry", onButtonTapped: @escaping () -> Void) {
        self.title = message.title ?? message.severity.title ?? "Error"
        self.summary = message.summary
        self.summaryFooter = nil
        self.details = message.details
        self.verboseDebugDescription = nil
        self.buttonText = buttonText
        self.onButtonTapped = onButtonTapped
    }

    public init(title: String, summary: String, summaryFooter: String? = nil, details: String? = nil, buttonText: String = "Retry", onButtonTapped: @escaping () -> Void) {
        self.title = title
        self.summary = summary
        self.summaryFooter = summaryFooter
        self.details = details
        self.verboseDebugDescription = nil
        self.buttonText = buttonText
        self.onButtonTapped = onButtonTapped
    }

    public var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .resizable()
                #if os(tvOS)
                    .frame(width: 64, height: 64)
                #else
                    .frame(width: 32, height: 32)
                #endif
                    .foregroundStyle(.red)
                    .padding(.vertical, 16)

                Text(title)
                    .font(.title2)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(summary)
                    .multilineTextAlignment(.leading)
                if let summaryFooter {
                    Text(summaryFooter)
                        .multilineTextAlignment(.leading)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if let verboseDebugDescription {
                VStack(alignment: .leading) {
                    Text("Technical Description")
                        .font(.headline)
                        .foregroundStyle(.tertiary)
                    ScrollView {
                        Text(verboseDebugDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
//                    .padding()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10)
//                .border(Color(.white), width: 1)
            }

            Button(action: { onButtonTapped() }, label: { Text(buttonText) })
                .buttonStyle(.bordered)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Previews

private struct Test: Codable {
    let a: Int
    let b: String
    let c: URL

    static func decodeFailedError() -> MirageError {
        do {
            _ = try JSONCoder.shared.decode(Test.self, from: Data("".utf8))
            throw NSError(domain: "Test", code: 0, userInfo: nil)
        } catch let error as MirageError {
            return error
        } catch {
            return .system(error)
        }
    }
}

#Preview {
    ErrorView(error: Test.decodeFailedError()) {}
}

#endif
