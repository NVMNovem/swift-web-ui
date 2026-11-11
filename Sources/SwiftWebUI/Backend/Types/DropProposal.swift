//
//  DropProposal.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

/// How a drop destination wants to handle the content currently over it.
///
/// SwiftUI's `DropProposal`, returned from ``DropDelegate/dropUpdated(info:)``.
public struct DropProposal: Hashable, Sendable {
    /// The operation the destination proposes.
    public let operation: DropOperation

    public init(operation: DropOperation) {
        self.operation = operation
    }
}
