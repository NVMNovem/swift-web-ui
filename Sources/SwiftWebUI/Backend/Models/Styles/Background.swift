//
//  Background.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftCSS

public struct Background: Equatable, Sendable, ExpressibleByStringLiteral {
    
    public var cssValue: String {
        cssColor?.rawValue ?? rawCSSValue
    }

    var cssColor: CSSColor?
    var rawCSSValue: String

    public init(_ cssValue: String) {
        self.cssColor = nil
        self.rawCSSValue = cssValue
    }

    public init(_ color: Color) {
        self.cssColor = color.cssColor
        self.rawCSSValue = color.cssValue
    }

    public init(stringLiteral value: String) {
        self.cssColor = nil
        self.rawCSSValue = value
    }
}

public extension Background {
    static func == (lhs: Background, rhs: Background) -> Bool {
        lhs.cssValue == rhs.cssValue
    }
}
