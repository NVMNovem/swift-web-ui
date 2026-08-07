//
//  Div.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 25/06/2026.
//

public struct Div<Content: View>: View {
    public typealias Body = Never
    public let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: Never { fatalError("Div primitive body unavailable") }
    public func makeViewNode(in context: ViewContext) -> ViewNode { .container(.init(kind: .div, children: content.makeViewNode(in: context.content).groupChildren)) }
}
