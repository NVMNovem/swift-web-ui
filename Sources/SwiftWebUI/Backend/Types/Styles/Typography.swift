//
//  Typography.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 30/06/2026.
//

import SwiftCSS

/// Text transform values for SwiftWebUI typography modifiers.
public enum TextTransform: Hashable, Sendable {
    case none
    case uppercase
    case lowercase
    case capitalize
}

/// Text alignment values for SwiftWebUI typography modifiers.
public enum TextAlignment: Hashable, Sendable {
    case leading
    case center
    case trailing
    case justified
}

/// Text decoration values for SwiftWebUI typography modifiers.
public enum TextDecoration: Hashable, Sendable {
    case none
    case underline
    case lineThrough
    case overline
}

extension TextTransform {
    var cssValue: TextTransformValue {
        switch self {
        case .none:
            .none
        case .uppercase:
            .uppercase
        case .lowercase:
            .lowercase
        case .capitalize:
            .capitalize
        }
    }
}

extension TextAlignment {
    var cssValue: TextAlignValue {
        switch self {
        case .leading:
            .left
        case .center:
            .center
        case .trailing:
            .right
        case .justified:
            .justify
        }
    }
}

extension TextDecoration {
    var cssValue: TextDecorationValue {
        switch self {
        case .none:
            .none
        case .underline:
            .underline
        case .lineThrough:
            .lineThrough
        case .overline:
            .overline
        }
    }
}
