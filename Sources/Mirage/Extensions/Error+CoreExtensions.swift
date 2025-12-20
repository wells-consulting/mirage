//
// Copyright 2025 Wells Consulting.
// This file is part of Mirage and is released under the MIT License.
//

import Foundation

public extension Swift.Error {
    var title: String? {
        (self as? (any Titled))?.title
    }
}
