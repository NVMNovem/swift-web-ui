//
//  EmptyView.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public struct EmptyView: View {
    public typealias Body = AnyView

    public init() {}

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
