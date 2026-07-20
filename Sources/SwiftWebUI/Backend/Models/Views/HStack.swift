//
//  HStack.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftCSS

public struct HStack<Content: View>: View {
    public typealias Body = Never
    public let alignment: Alignment
    public let spacing: SwiftCSS.Length?
    public let content: Content

    public init(
        alignment: Alignment = .center,
        spacing: SwiftCSS.Length? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    public var body: Never { fatalError("HStack primitive body unavailable") }
    public func makeViewNode() -> ViewNode {
        .container(.init(kind: .horizontal(alignment: alignment, spacing: spacing), children: content.makeViewNode().groupChildren))
    }
}
