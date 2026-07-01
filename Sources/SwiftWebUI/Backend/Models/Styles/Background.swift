//
//  Background.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftCSS

/// A SwiftWebUI background value lowered to SwiftCSS declarations during rendering.
///
/// Prefer color-backed backgrounds for design tokens. Raw CSS strings are
/// available as escape hatches.
public struct Background: Equatable, Sendable, ExpressibleByStringLiteral {
    
    public var cssValue: String {
        color?.rawValue ?? rawCSSValue
    }

    var color: SwiftCSS.Color?
    var rawCSSValue: String

    public init(_ cssValue: String) {
        self.color = nil
        self.rawCSSValue = cssValue
    }

    public init(_ color: SwiftCSS.Color) {
        self.color = color
        self.rawCSSValue = color.rawValue
    }

    public init(stringLiteral value: String) {
        self.color = nil
        self.rawCSSValue = value
    }
}

public extension Background {
    static func == (lhs: Background, rhs: Background) -> Bool {
        lhs.cssValue == rhs.cssValue
    }
}
