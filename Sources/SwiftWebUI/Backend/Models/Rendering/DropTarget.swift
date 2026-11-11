//
//  DropTarget.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

/// How an element takes part in drops.
///
/// Produced by every `onDrop` modifier: the closure-based forms are delegates
/// too, so a renderer only ever drives this one shape. It owns the semantics a
/// renderer must not repeat — which content types are welcome, and that a `nil`
/// proposal means ``DropOperation/copy`` — and leaves the renderer only the
/// browser's events.
public struct DropTarget {
    /// The content types this element accepts.
    @_spi(Rendering)
    public let supportedContentTypes: [UTType]

    private let validate: (DropInfo) -> Bool
    private let entered: (DropInfo) -> Void
    private let updated: (DropInfo) -> DropProposal?
    private let exited: (DropInfo) -> Void
    private let perform: (DropInfo) -> Bool

    /// Wraps `delegate`, running each call with the environment objects in effect now.
    @_spi(Rendering)
    public init<Delegate: DropDelegate>(of supportedContentTypes: [UTType], delegate: Delegate) {
        self.supportedContentTypes = supportedContentTypes
        validate = EnvironmentStorage.capturing { delegate.validateDrop(info: $0) }
        entered = EnvironmentStorage.capturing { delegate.dropEntered(info: $0) }
        updated = EnvironmentStorage.capturing { delegate.dropUpdated(info: $0) }
        exited = EnvironmentStorage.capturing { delegate.dropExited(info: $0) }
        perform = EnvironmentStorage.capturing { delegate.performDrop(info: $0) }
    }

    /// Whether a drag that has just arrived is welcome.
    ///
    /// A drag carrying nothing of a supported type is refused without asking the delegate.
    @_spi(Rendering)
    public func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: supportedContentTypes) && validate(info)
    }

    @_spi(Rendering)
    public func dropEntered(info: DropInfo) {
        entered(info)
    }

    /// The operation a welcome drag would perform where it is now.
    @_spi(Rendering)
    public func dropUpdated(info: DropInfo) -> DropOperation {
        updated(info)?.operation ?? .copy
    }

    @_spi(Rendering)
    public func dropExited(info: DropInfo) {
        exited(info)
    }

    @_spi(Rendering)
    public func performDrop(info: DropInfo) -> Bool {
        perform(info)
    }
}
