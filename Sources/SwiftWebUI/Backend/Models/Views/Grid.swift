//
//  Grid.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 29/06/2026.
//

public struct Grid<Content: View>: View {
    public typealias Body = AnyView

    var spacing: Length?
    var content: Content

    public init(spacing: Length? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
