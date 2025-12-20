//
// Copyright 2025 Wells Consulting.
// This file is part of Mirage and is released under the MIT License.
//

import Foundation

/// Types providing summary text.
///
/// ```swift
///
/// let lotsOfData = try await URLSession.shared.data(for: urlRequest)
///
/// print(lotsOfData.summary)
/// ```
///     25.8 GB
///
public protocol Summarizable {
    /// Optional summary text
    var summary: String? { get }
}
