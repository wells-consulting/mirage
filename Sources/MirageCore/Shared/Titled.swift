//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// Types providing titles.

public protocol Titled {
    /// Optional text suitable for user-facing titles
    var title: String? { get }
}
