//
// Copyright 2025 Wells Consulting.
// This file is part of Mirage and is released under the MIT License.
//

import Foundation

#if canImport(UIKit)

import UIKit

public typealias OSColor = UIColor
public typealias OSFont = UIFont
public typealias OSImage = UIImage

#elseif canImport(AppKit)

import AppKit

public typealias OSColor = NSColor
public typealias OSFont = NSFont
public typealias OSImage = NSImage

#endif
