//
//  EmptyView.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

/// A view that renders no HTML.
public struct EmptyView: View {
    public typealias Body = AnyView

    public init() {}

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
