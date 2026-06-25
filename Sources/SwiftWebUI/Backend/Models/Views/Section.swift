//
//  Section.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public struct Section<Content: View>: View {
    public typealias Body = AnyView

    var content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
