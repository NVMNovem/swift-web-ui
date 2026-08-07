//
//  Grid.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 29/06/2026.
//

import SwiftCSS

public struct Grid<Content: View>: View {
    public typealias Body = Never
    public let spacing: SwiftCSS.Length?
    public let content: Content

    public init(spacing: SwiftCSS.Length? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: Never { fatalError("Grid primitive body unavailable") }
    public func makeViewNode(in context: ViewContext) -> ViewNode {
        .container(.init(kind: .grid(spacing: spacing), children: content.makeViewNode(in: context.content).groupChildren))
    }
}
