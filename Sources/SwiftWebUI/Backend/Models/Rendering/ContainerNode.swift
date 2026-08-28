//
//  ContainerNode.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

import SwiftCSS

public struct ContainerNode {
    public let kind: ContainerKind
    public let children: [ViewNode]

    public init(kind: ContainerKind, children: [ViewNode]) {
        self.kind = kind
        self.children = children
    }
}

public enum ContainerKind {
    case group
    case vertical(alignment: Alignment, spacing: SwiftCSS.Length?)
    case horizontal(alignment: Alignment, spacing: SwiftCSS.Length?)
    case grid(spacing: SwiftCSS.Length?)
    /// Children share one box, painted in document order.
    case layered(alignment: Alignment)
    /// A browser `dialog` element.
    ///
    /// `presentation` is reconciled state rather than an imperative call, and
    /// `onDismiss` runs when the browser closes the dialog on its own.
    case dialog(presentation: DialogPresentation, onDismiss: ActionIntent?)
    case div
    case article
    case section
    case form
    case label(text: String?)
    case footer
    case template(name: String)
    /// An explicitly named element, for markup SwiftWebUI attaches no semantics to.
    case element(tag: String)
}
