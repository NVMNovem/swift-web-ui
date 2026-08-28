//
//  ZStack.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 28/08/2026.
//

import SwiftCSS

/// Layers its children in a single box, one on top of the next.
///
/// Children are laid out in one grid cell rather than positioned absolutely, so
/// the stack still sizes itself to its largest child. Later children paint over
/// earlier ones in document order, which means a layered stack needs no
/// hand-assigned `z-index`.
public struct ZStack<Content: View>: View {
    public typealias Body = Never
    public let alignment: Alignment
    public let content: Content

    public init(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.content = content()
    }

    public var body: Never { fatalError("ZStack primitive body unavailable") }
    public func makeViewNode(in context: ViewContext) -> ViewNode {
        .container(.init(
            kind: .layered(alignment: alignment),
            children: content.makeViewNode(in: context.content).groupChildren
        ))
    }
}
