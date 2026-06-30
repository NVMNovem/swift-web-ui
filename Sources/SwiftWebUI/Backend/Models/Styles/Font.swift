//
//  Font.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftCSS

private struct FontDeclaration: Hashable, Sendable {
    
    var name: String
    var value: String

    var cssProperty: any CSSProperty {
        RawProperty(name, value)
    }
}

public struct Font: Hashable, Sendable {

    public enum Weight: Hashable, Sendable {
        case ultraLight
        case thin
        case light
        case regular
        case medium
        case semibold
        case bold
        case heavy
        case black
        case weight(Int)
    }

    public enum Design: Hashable, Sendable {
        case `default`
        case serif
        case rounded
        case monospaced
    }

    private var declarations: [FontDeclaration]

    private init(_ cssProperties: [any CSSProperty]) {
        self.declarations = cssProperties.map {
            FontDeclaration(name: $0.name, value: $0.value)
        }
    }

    public static func system(
        size: Double,
        weight: Weight? = nil,
        design: Design? = nil
    ) -> Font {
        var cssProperties: [any CSSProperty] = [
            FontSize(Length("\(formatFontNumber(size))px"))
        ]

        if let weight {
            cssProperties.append(FontWeight(weight.cssValue))
        }

        if let fontFamily = design?.fontFamily {
            cssProperties.append(fontFamily)
        }

        return Font(cssProperties)
    }

    public static let largeTitle = system(size: 34, weight: .regular)
    public static let title = system(size: 28, weight: .regular)
    public static let title2 = system(size: 22, weight: .regular)
    public static let title3 = system(size: 20, weight: .regular)
    public static let headline = system(size: 17, weight: .semibold)
    public static let subheadline = system(size: 15, weight: .regular)
    public static let body = system(size: 17, weight: .regular)
    public static let callout = system(size: 16, weight: .regular)
    public static let footnote = system(size: 13, weight: .regular)
    public static let caption = system(size: 12, weight: .regular)
    public static let caption2 = system(size: 11, weight: .regular)

    var cssProperties: [any CSSProperty] {
        declarations.map(\.cssProperty)
    }
}

public typealias FontToken = Font

private extension Font.Weight {

    var cssValue: FontWeight.Value {
        switch self {
        case .ultraLight:
            .weight(100)
        case .thin:
            .weight(200)
        case .light:
            .weight(300)
        case .regular:
            .weight(400)
        case .medium:
            .weight(500)
        case .semibold:
            .weight(600)
        case .bold:
            .weight(700)
        case .heavy:
            .weight(800)
        case .black:
            .weight(900)
        case .weight(let value):
            .weight(value)
        }
    }
}

private extension Font.Design {

    var fontFamily: FontFamily? {
        switch self {
        case .default:
            nil
        case .serif:
            FontFamily("ui-serif, Georgia, Cambria, \"Times New Roman\", Times, serif")
        case .rounded:
            FontFamily("ui-rounded, \"SF Pro Rounded\", \"Nunito Sans\", system-ui, sans-serif")
        case .monospaced:
            FontFamily("ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, \"Liberation Mono\", monospace")
        }
    }
}

private func formatFontNumber(_ value: Double) -> String {
    if value.rounded() == value {
        return "\(Int(value))"
    }

    return "\(value)"
}
