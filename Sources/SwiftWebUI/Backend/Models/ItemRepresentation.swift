//
//  ItemRepresentation.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

/// One form of a dragged item: its content type and its content.
///
/// A browser drag carries strings keyed by MIME type — `DataTransfer.setData(_:_:)`
/// and `getData(_:)` — so that is all a representation is.
@_spi(Rendering)
public struct ItemRepresentation: Hashable, Sendable {
    public let contentType: UTType
    public let value: String

    public init(contentType: UTType, value: String) {
        self.contentType = contentType
        self.value = value
    }
}
