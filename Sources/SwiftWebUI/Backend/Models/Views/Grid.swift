//
//  Grid.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 29/06/2026.
//

import SwiftCSS

/// A grid layout container backed by SwiftCSS layout declarations.
public struct Grid<Content: View>: View {
    public typealias Body = AnyView

    var spacing: SwiftCSS.Length?
    var content: Content

    public init(spacing: SwiftCSS.Length? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
