//
//  Color.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftCSS

public struct Color: Hashable, Sendable, ExpressibleByStringLiteral {

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

    public static func css(_ value: String) -> Color {
        Color(value)
    }

    public static let accent = Color.css("var(--accent)")
    public static let panel = Color.css("var(--panel)")
    public static let border = Color.css("var(--border)")
    public static let muted = Color.css("var(--muted)")
    public static let primary = Color.css("var(--primary)")
    public static let white = Color.css("#fff")

    public static let secondary = Color.muted
    public static let surface = Color.panel
    public static let clear = Color.css("transparent")
    public static let black = Color.css("#000")
    
    public static func == (lhs: Color, rhs: Color) -> Bool {
        lhs.cssValue == rhs.cssValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(cssValue)
    }
}
