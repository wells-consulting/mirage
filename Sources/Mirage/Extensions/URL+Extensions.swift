//
// Copyright 2025 Wells Consulting.
// This file is part of Mirage and is released under the MIT License.

import Foundation

public extension URL {
    init?(string: String?) {
        if let string, let url = URL(string: string) {
            self = url
        } else {
            return nil
        }
    }

    static func from(_ string: String) throws -> URL {
        guard let url = URL(string: string) else {
            throw Mirage.Error(description: "Supplied string \"\(string)\" is not a valid URL.", title: "URL Parsing Failed")
        }
        return url
    }
}
