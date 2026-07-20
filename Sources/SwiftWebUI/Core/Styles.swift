import SwiftCSS

public enum SemanticRole: Hashable, Sendable {
    case span
    case p
    case h1
    case h2
    case h3
    case h4
    case h5
    case h6
}

public enum Alignment: String, Hashable, Sendable {
    case leading
    case center
    case trailing
    case top
    case bottom
}

public struct Edge: OptionSet, Sendable {
    public typealias Set = Edge
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public static let top = Edge(rawValue: 1 << 0)
    public static let leading = Edge(rawValue: 1 << 1)
    public static let bottom = Edge(rawValue: 1 << 2)
    public static let trailing = Edge(rawValue: 1 << 3)
    public static let horizontal: Edge = [.leading, .trailing]
    public static let vertical: Edge = [.top, .bottom]
    public static let all: Edge = [.top, .leading, .bottom, .trailing]
}

public enum BorderLineStyle: String, Hashable, Sendable {
    case none
    case solid
    case dashed
    case dotted
    case double
}

public enum ClipShape: Equatable, Sendable {
    case capsule
}

public enum TextTransform: Hashable, Sendable {
    case none
    case uppercase
    case lowercase
    case capitalize
}

public enum TextAlignment: Hashable, Sendable {
    case leading
    case center
    case trailing
    case justified
}

public enum TextDecoration: Hashable, Sendable {
    case none
    case underline
    case lineThrough
    case overline
}

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
