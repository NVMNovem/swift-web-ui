//
//  ButtonStyleToken.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftCSS

public struct ButtonStyleToken: Sendable {
    public let className: String?
    public let declarations: [SwiftCSS.CSSDeclaration]

    public init(
        className: String? = nil,
        declarations: [SwiftCSS.CSSDeclaration]
    ) {
        self.className = className
        self.declarations = declarations
    }

    public static let primary = ButtonStyleToken(
        className: "button primary",
        declarations: [
            Display(.inlineFlex).cssDeclaration,
            AlignItems(.center).cssDeclaration,
            JustifyContent(.center).cssDeclaration,
            Gap(.px(8)).cssDeclaration,
            Padding("10px 16px").cssDeclaration,
            BackgroundColor(SwiftCSS.Color("#000")).cssDeclaration,
            SwiftCSS.Color("#fff").cssDeclaration,
            BorderRadius(.px(999)).cssDeclaration,
            Border("1px solid transparent").cssDeclaration,
            BoxShadow("0 12px 30px rgba(0, 0, 0, 0.18)").cssDeclaration,
            SwiftCSS.TextDecoration(TextDecorationValue.none).cssDeclaration,
            RawProperty("font-weight", "700").cssDeclaration,
        ]
    )

    public static let secondary = ButtonStyleToken(
        className: "button secondary",
        declarations: [
            Display(.inlineFlex).cssDeclaration,
            AlignItems(.center).cssDeclaration,
            JustifyContent(.center).cssDeclaration,
            Gap(.px(8)).cssDeclaration,
            Padding("10px 16px").cssDeclaration,
            BackgroundColor(SwiftCSS.Color("#fff")).cssDeclaration,
            SwiftCSS.Color("#000").cssDeclaration,
            BorderRadius(.px(999)).cssDeclaration,
            Border("1px solid #000").cssDeclaration,
            SwiftCSS.TextDecoration(TextDecorationValue.none).cssDeclaration,
            RawProperty("font-weight", "700").cssDeclaration,
        ]
    )
}
