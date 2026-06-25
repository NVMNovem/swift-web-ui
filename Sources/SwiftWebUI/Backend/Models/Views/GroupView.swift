//
//  GroupView.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public struct GroupView: View {
    public typealias Body = AnyView

    var children: [AnyView]

    public init(_ children: [AnyView]) {
        self.children = children
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
