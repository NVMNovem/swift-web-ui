//
//  Footer.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 25/06/2026.
//

public struct Footer<Content: View>: View {
    public typealias Body = Never
    public let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: Never { fatalError("Footer primitive body unavailable") }
    public func makeViewNode(in context: ViewContext) -> ViewNode { .container(.init(kind: .footer, children: content.makeViewNode(in: context.content).groupChildren)) }
}
