//
//  Typography.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 30/06/2026.
//

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
