//
//  ButtonStyleToken.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftCSS

public struct ButtonStyleToken: Equatable, Sendable {
    
    public var className: String?
    public var cssProperties: [any CSSProperty]

    public init(className: String? = nil, cssProperties: [any CSSProperty]) {
        self.className = className
        self.cssProperties = cssProperties
    }

    public static func == (lhs: ButtonStyleToken, rhs: ButtonStyleToken) -> Bool {
        lhs.className == rhs.className
            && lhs.cssProperties.map(\.name) == rhs.cssProperties.map(\.name)
            && lhs.cssProperties.map(\.value) == rhs.cssProperties.map(\.value)
    }
}

public extension ButtonStyleToken {
    
    static let primary = ButtonStyleToken(
        className: "button primary",
        cssProperties: [
            Display(.inlineFlex),
            AlignItems(.center),
            JustifyContent(.center),
            Gap(.px(8)),
            Padding("10px 16px"),
            BackgroundColor(Color.accent.cssColor),
            SwiftCSS.Color(Color.white.cssColor),
            BorderRadius(.px(999)),
            Border("1px solid transparent"),
            BoxShadow("0 12px 30px rgba(37, 99, 235, 0.22)"),
            RawProperty("text-decoration", "none"),
            RawProperty("font-weight", "700")
        ]
    )

    static let secondary = ButtonStyleToken(
        className: "button secondary",
        cssProperties: [
            Display(.inlineFlex),
            AlignItems(.center),
            JustifyContent(.center),
            Gap(.px(8)),
            Padding("10px 16px"),
            BackgroundColor(Color.surface.cssColor),
            SwiftCSS.Color(Color.primary.cssColor),
            BorderRadius(.px(999)),
            Border("1px solid \(Color.border.cssValue)"),
            RawProperty("text-decoration", "none"),
            RawProperty("font-weight", "700")
        ]
    )
}
