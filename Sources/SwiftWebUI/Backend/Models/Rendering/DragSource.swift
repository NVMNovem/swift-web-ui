//
//  DragSource.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

/// What an element hands over when a drag starts on it.
///
/// Produced by ``View/onDrag(_:)``. The provider is built when the drag starts,
/// not when the view is lowered, so it carries the content as it is at that moment.
public struct DragSource {
    private let provider: () -> ItemProvider

    @_spi(Rendering)
    public init(_ provider: @escaping () -> ItemProvider) {
        self.provider = provider
    }

    /// Builds the provider and returns what it carries.
    @_spi(Rendering)
    public func representations() -> [ItemRepresentation] {
        provider().representations
    }
}
