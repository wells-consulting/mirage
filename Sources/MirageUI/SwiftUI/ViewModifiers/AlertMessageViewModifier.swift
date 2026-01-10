//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

#if canImport(SwiftUI)

import MirageCore
import SwiftUI

private struct AlertMessageViewModifier: ViewModifier {

    @Binding var message: Message?

    func body(content: Content) -> some View {
        content
            .alert(isPresented: .constant(message != nil)) {
                Alert(
                    title: Text(message?.title?.capitalized ?? "Alert"),
                    message: Text(message?.text ?? "No text was supplied"),
                    dismissButton: .default(Text("OK"), action: { message = nil })
                )
            }
    }
}

public extension View {
    func alertMessage(_ message: Binding<Message?>) -> some View {
        modifier(AlertMessageViewModifier(message: message))
    }
}

#endif
