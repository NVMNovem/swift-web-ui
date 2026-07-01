//
//  VStack.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftCSS

/// A vertical layout container backed by SwiftCSS layout declarations.
public struct VStack<Content: View>: View {
    public typealias Body = AnyView

    var alignment: Alignment
    var spacing: SwiftCSS.Length?
    var content: Content

    public init(alignment: Alignment = .center, spacing: SwiftCSS.Length? = nil, @ViewBuilder content: () -> Content) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
