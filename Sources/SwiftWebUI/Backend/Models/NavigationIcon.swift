//
//  NavigationIcon.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 02/09/2026.
//

/// An icon shown by the browser for the current document.
///
/// Use ``svg(_:)`` for literal SVG markup; renderers encode it as an inline
/// favicon data URL. Use ``url(_:)`` for a browser-resolvable icon resource.
/// Asset copying remains the responsibility of the application build tooling.
public enum NavigationIcon: Equatable, Sendable {
    /// Literal SVG markup for an inline browser tab icon.
    case svg(String)
    /// An icon at a browser-resolvable path or URL of any supported format.
    case url(String)

    @_spi(Rendering)
    public var href: String {
        switch self {
        case .svg(let markup):
            "data:image/svg+xml,\(Self.percentEncoded(markup))"
        case .url(let source):
            source
        }
    }

    @_spi(Rendering)
    public var mimeType: String? {
        if case .svg = self { return "image/svg+xml" }
        return nil
    }

    /// Encodes each non-unreserved UTF-8 byte so arbitrary SVG markup remains
    /// one data-URL payload rather than being interpreted as URL syntax.
    private static func percentEncoded(_ value: String) -> String {
        var result = ""
        result.reserveCapacity(value.utf8.count * 3)

        for byte in value.utf8 {
            switch byte {
            case 48...57, 65...90, 97...122, 45, 46, 95, 126:
                result.unicodeScalars.append(UnicodeScalar(byte))
            default:
                result.append("%")
                result.append(hexadecimalCharacter(for: byte >> 4))
                result.append(hexadecimalCharacter(for: byte & 0x0F))
            }
        }
        return result
    }

    private static func hexadecimalCharacter(for value: UInt8) -> Character {
        switch value {
        case 0: "0"
        case 1: "1"
        case 2: "2"
        case 3: "3"
        case 4: "4"
        case 5: "5"
        case 6: "6"
        case 7: "7"
        case 8: "8"
        case 9: "9"
        case 10: "A"
        case 11: "B"
        case 12: "C"
        case 13: "D"
        case 14: "E"
        default: "F"
        }
    }
}
