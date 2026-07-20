//
//  Background.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftCSS

public struct Background: Equatable, Sendable, ExpressibleByStringLiteral {
    public let color: SwiftCSS.Color?
    public let rawCSSValue: String

    public var cssValue: String { color?.rawValue ?? rawCSSValue }

    public init(_ cssValue: String) {
        self.color = nil
        self.rawCSSValue = cssValue
    }

    public init(_ color: SwiftCSS.Color) {
        self.color = color
        self.rawCSSValue = color.rawValue
    }

    public init(stringLiteral value: String) {
        self.init(value)
    }

    public static func == (lhs: Background, rhs: Background) -> Bool {
        lhs.cssValue == rhs.cssValue
    }
}
