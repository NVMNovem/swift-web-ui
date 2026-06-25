//
//  FontToken.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftCSS

struct FontDeclaration: Equatable, Sendable {
    
    var name: String
    var value: String

    var cssProperty: any CSSProperty {
        RawProperty(name, value)
    }
}

public struct FontToken: Equatable, Sendable, ExpressibleByStringLiteral {

    var declarations: [FontDeclaration]

    public init(_ cssProperties: [any CSSProperty]) {
        self.declarations = cssProperties.map {
            FontDeclaration(name: $0.name, value: $0.value)
        }
    }

    public init(stringLiteral value: String) {
        declarations = [FontDeclaration(name: "font", value: value)]
    }

    public static let body = FontToken([
        FontSize("1rem"),
        LineHeight("1.6")
    ])

    public static let heroTitle = FontToken([
        FontSize("clamp(2.5rem, 6vw, 5.5rem)"),
        FontWeight(.weight(760)),
        LineHeight("0.98")
    ])

    var cssProperties: [any CSSProperty] {
        declarations.map(\.cssProperty)
    }
}
