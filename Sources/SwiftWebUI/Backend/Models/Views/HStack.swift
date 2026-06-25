//
//  HStack.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public struct HStack<Content: View>: View {
    public typealias Body = AnyView

    var alignment: Alignment
    var spacing: Length?
    var content: Content

    public init(alignment: Alignment = .center, spacing: Length? = nil, @ViewBuilder content: () -> Content) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
