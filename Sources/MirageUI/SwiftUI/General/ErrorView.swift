//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import MirageCore
import SwiftUI

public struct ErrorView: View {

    private let title: String
    private let message: String
    private let buttonText: String
    private let onButtonTapped: () -> Void

    public init(error: any Error, buttonText: String = "Retry", onButtonTapped: @escaping () -> Void) {
        self.title = (error as? (any Titled))?.title ?? "Error"
        self.message = error.localizedDescription
        self.buttonText = buttonText
        self.onButtonTapped = onButtonTapped
    }

    public init(message: Message, buttonText: String = "Retry", onButtonTapped: @escaping () -> Void) {
        self.title = message.title ?? message.severity.title ?? "Error"
        self.message = message.text
        self.buttonText = buttonText
        self.onButtonTapped = onButtonTapped
    }

    public init(title: String, message: String, buttonText: String = "Retry", onButtonTapped: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.buttonText = buttonText
        self.onButtonTapped = onButtonTapped
    }

    public var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundStyle(.red)
                .padding(.vertical, 16)

            Text(title)
                .font(.title2)

            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding()

            Button(action: { onButtonTapped() }, label: { Text(buttonText) })
                .buttonStyle(.bordered)
                .padding()
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
    }
}

#endif
