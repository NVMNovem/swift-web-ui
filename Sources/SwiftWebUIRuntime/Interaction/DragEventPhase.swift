//
//  DragEventPhase.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

/// The browser drag events a drop destination listens to.
enum DragEventPhase: Equatable {
    /// `dragenter`: a drag arrived over the element or one of its descendants.
    case enter
    /// `dragover`: a drag is moving over the element.
    case over
    /// `dragleave`, when the drag has left the element itself rather than moved
    /// between its descendants. The backend filters the latter out.
    case leave
    /// `drop`: the drag was released over the element.
    case drop
}
