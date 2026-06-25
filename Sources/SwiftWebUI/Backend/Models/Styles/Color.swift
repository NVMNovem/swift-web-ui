//
//  Color.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftCSS

public struct Color: Equatable, Sendable, ExpressibleByStringLiteral {

    public var cssValue: String {
        cssColor.rawValue
    }

    var cssColor: CSSColor

    public init(_ cssValue: String) {
        self.cssColor = CSSColor(cssValue)
    }

    public init(stringLiteral value: String) {
        self.cssColor = CSSColor(value)
    }

    public static let primary = Color("var(--color-primary, #111827)")
    public static let secondary = Color("var(--color-secondary, #4b5563)")
    public static let accent = Color("var(--color-accent, #2563eb)")
    public static let surface = Color("var(--color-surface, #ffffff)")
    public static let border = Color("var(--color-border, #d1d5db)")
    public static let clear = Color("transparent")
    public static let white = Color("#fff")
    public static let black = Color("#000")
}

public extension Color {
    static func == (lhs: Color, rhs: Color) -> Bool {
        lhs.cssValue == rhs.cssValue
    }
}
