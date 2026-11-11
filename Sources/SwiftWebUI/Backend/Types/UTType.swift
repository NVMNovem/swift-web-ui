//
//  UTType.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

/// A kind of content that can be dragged and dropped.
///
/// The counterpart of `UniformTypeIdentifiers.UTType`, so that
/// `.onDrop(of: [.plainText], …)` reads the way it does in SwiftUI.
///
/// On the web a dragged item's kind is a MIME type — the `format` of
/// `DataTransfer.setData(_:_:)` — so that is what a `UTType` holds here, and
/// ``identifier`` *is* that MIME type (`"text/plain"`), not an Apple uniform type
/// identifier (`"public.plain-text"`). Pass ``identifier`` wherever SwiftUI takes
/// a type identifier string and the two stay in agreement.
///
/// MIME types are compared without their parameters and without regard to case,
/// so `text/plain;charset=utf-8` conforms to ``plainText``. A subtype of `*` is
/// an abstract type that only exists to be matched against: ``text`` is any
/// `text/…` type and ``item`` is any type at all, mirroring Apple's hierarchy.
public struct UTType: Hashable, Sendable {
    /// The MIME type this content type stands for.
    public let identifier: String

    /// Creates the content type for a MIME type such as `"application/json"`.
    ///
    /// Returns `nil` when `mimeType` has no `/`, which no MIME type lacks.
    public init?(mimeType: String) {
        guard mimeType.utf8.contains(UInt8(ascii: "/")) else { return nil }
        self.identifier = Self.normalized(mimeType)
    }

    /// The MIME type a browser uses for this content type.
    ///
    /// Always ``identifier``. Kept so that code written against Apple's `UTType`
    /// keeps compiling.
    public var preferredMIMEType: String? { identifier }

    /// Whether content of this type can stand in for `supertype`.
    ///
    /// A type conforms to itself, `text/html` conforms to ``text``, and every type
    /// conforms to ``item``.
    public func conforms(to supertype: UTType) -> Bool {
        let own = Self.parts(of: identifier)
        let other = Self.parts(of: supertype.identifier)
        if other.type == "*" { return true }
        guard own.type == other.type else { return false }
        return other.subtype == "*" || own.subtype == other.subtype
    }

    private init(normalizedMIMEType: String) {
        self.identifier = normalizedMIMEType
    }

    /// Lowercases the ASCII letters of a MIME type and trims surrounding spaces.
    ///
    /// MIME types are ASCII and case-insensitive. Doing it by byte keeps the core free
    /// of Unicode case tables, which Embedded Swift would otherwise have to link.
    private static func normalized(_ mimeType: String) -> String {
        var bytes = Array(mimeType.utf8)
        while bytes.first == UInt8(ascii: " ") { bytes.removeFirst() }
        while bytes.last == UInt8(ascii: " ") { bytes.removeLast() }
        for index in bytes.indices where bytes[index] >= UInt8(ascii: "A") && bytes[index] <= UInt8(ascii: "Z") {
            bytes[index] += 32
        }
        return String(decoding: bytes, as: UTF8.self)
    }

    /// Splits `type/subtype;parameters` into its type and subtype.
    private static func parts(of identifier: String) -> (type: String, subtype: String) {
        let bytes = Array(identifier.utf8)
        let essence = bytes[..<(bytes.firstIndex(of: UInt8(ascii: ";")) ?? bytes.endIndex)]
        guard let slash = essence.firstIndex(of: UInt8(ascii: "/")) else {
            return (String(decoding: essence, as: UTF8.self), "")
        }
        return (
            String(decoding: essence[..<slash], as: UTF8.self),
            String(decoding: essence[(slash + 1)...], as: UTF8.self)
        )
    }
}

public extension UTType {
    /// Plain text: `text/plain`.
    static let plainText = UTType(normalizedMIMEType: "text/plain")
    /// Plain text in UTF-8. Browsers carry all text as `text/plain`, so this is the
    /// same MIME type as ``plainText``.
    static let utf8PlainText = UTType(normalizedMIMEType: "text/plain")
    /// A list of URLs, one per line: `text/uri-list`.
    static let url = UTType(normalizedMIMEType: "text/uri-list")
    /// HTML markup: `text/html`.
    static let html = UTType(normalizedMIMEType: "text/html")
    /// JSON: `application/json`.
    static let json = UTType(normalizedMIMEType: "application/json")
    /// Any text: `text/*`. Abstract — match against it, do not register it.
    static let text = UTType(normalizedMIMEType: "text/*")
    /// Any content at all: `*/*`. Abstract — match against it, do not register it.
    static let item = UTType(normalizedMIMEType: "*/*")
}
