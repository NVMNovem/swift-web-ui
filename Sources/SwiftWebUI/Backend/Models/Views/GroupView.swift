//
//  GroupView.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public struct Group<Content: View>: View {
    public typealias Body = Never
    public let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: Never { fatalError("Group primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .container(.init(kind: .group, children: content.makeViewNode().groupChildren)) }
}
