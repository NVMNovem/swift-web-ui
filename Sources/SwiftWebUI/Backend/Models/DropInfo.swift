//
//  DropInfo.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

/// The current state of a drag over a drop destination.
///
/// SwiftUI's `DropInfo`, handed to every ``DropDelegate`` method.
///
/// A browser only lets a page read what a drag carries once it is dropped. Until
/// then ``hasItemsConforming(to:)`` can tell what *kinds* of content are coming,
/// but ``itemProviders(for:)`` returns providers only inside
/// ``DropDelegate/performDrop(info:)``.
public struct DropInfo: Sendable {
    /// Where the pointer is, in the drop destination's own coordinate space.
    public let location: Point

    /// The content types the drag carries.
    private let contentTypes: [UTType]

    /// What the drag carries, once it has been dropped.
    private let representations: [ItemRepresentation]?

    /// Describes a drag in progress, or — with `representations` — one that was dropped.
    @_spi(Rendering)
    public init(location: Point, contentTypes: [UTType], representations: [ItemRepresentation]? = nil) {
        self.location = location
        self.contentTypes = contentTypes
        self.representations = representations
    }

    /// Whether the drag carries content conforming to any of `contentTypes`.
    public func hasItemsConforming(to contentTypes: [UTType]) -> Bool {
        self.contentTypes.contains { carried in
            contentTypes.contains { carried.conforms(to: $0) }
        }
    }

    /// The dropped content conforming to any of `contentTypes`.
    ///
    /// A browser drag is a single item that may carry several representations, so
    /// this returns at most one provider. It is empty before the drop, and when
    /// nothing dropped conforms.
    public func itemProviders(for contentTypes: [UTType]) -> [ItemProvider] {
        guard let representations else { return [] }
        let conforming = representations.filter { representation in
            contentTypes.contains { representation.contentType.conforms(to: $0) }
        }
        guard !conforming.isEmpty else { return [] }
        return [ItemProvider(representations: conforming)]
    }
}
