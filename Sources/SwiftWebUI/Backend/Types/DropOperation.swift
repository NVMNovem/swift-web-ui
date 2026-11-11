//
//  DropOperation.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

/// What a drop would do with the content being dragged.
///
/// SwiftUI's `DropOperation`. The browser shows it as the pointer's drop effect:
/// ``copy`` and ``move`` become `copy` and `move`, while ``cancel`` and
/// ``forbidden`` both refuse the drop and show `none`.
public enum DropOperation: Hashable, Sendable {
    /// Do not accept the drop.
    case cancel
    /// The drop is not allowed here.
    case forbidden
    /// Copy the content into the destination.
    case copy
    /// Move the content into the destination.
    case move

    /// Whether this operation lets the drop happen.
    @_spi(Rendering)
    public var acceptsDrop: Bool {
        switch self {
        case .copy, .move: true
        case .cancel, .forbidden: false
        }
    }
}
