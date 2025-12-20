//
// Copyright 2025 Wells Consulting.
// This file is part of MirageKit and is released under the MIT License.
//

import Foundation

/// Types with unstructured additional data.

public protocol UserInfoProviding {
    var userInfo: [String: any Sendable]? { get }
}
