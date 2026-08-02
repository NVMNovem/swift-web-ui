//
//  Font.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

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

        public var numericValue: Int {
            switch self {
            case .ultraLight: 100
            case .thin: 200
            case .light: 300
            case .regular: 400
            case .medium: 500
            case .semibold: 600
            case .bold: 700
            case .heavy: 800
            case .black: 900
            case .weight(let value): value
            }
        }
    }

    public enum Design: Hashable, Sendable {
        case `default`
        case serif
        case rounded
        case monospaced
    }

    public let size: Double
    public let weight: Weight?
    public let design: Design?

    public static func system(
        size: Double,
        weight: Weight? = nil,
        design: Design? = nil
    ) -> Font {
        Font(size: size, weight: weight, design: design)
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
}

public typealias FontToken = Font
