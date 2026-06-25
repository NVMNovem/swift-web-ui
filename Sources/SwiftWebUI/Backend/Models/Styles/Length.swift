//
//  Length.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftCSS

public struct Length: Equatable, Sendable, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    
    public var cssValue: String {
        cssLength.rawValue
    }

    var cssLength: CSSLength

    public init(_ cssValue: String) {
        self.cssLength = CSSLength(cssValue)
    }

    public init(integerLiteral value: Int) {
        self.cssLength = .px(value)
    }

    public init(floatLiteral value: Double) {
        self.cssLength = CSSLength("\(formatLengthNumber(value))px")
    }

    public static func px(_ value: Int) -> Length { Length("\(value)px") }
    public static func rem(_ value: Double) -> Length { Length("\(value)rem") }
    public static func percent(_ value: Double) -> Length { Length("\(formatLengthNumber(value))%") }
    public static let auto = Length("auto")
}

public extension Length {
    static func == (lhs: Length, rhs: Length) -> Bool {
        lhs.cssValue == rhs.cssValue
    }
}

private func formatLengthNumber(_ value: Double) -> String {
    value.rounded(.towardZero) == value ? String(Int(value)) : String(value)
}
