//
//  Article.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 25/06/2026.
//

public struct Article<Content: View>: View {
    public typealias Body = Never
    public let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: Never { fatalError("Article primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .container(.init(kind: .article, children: content.makeViewNode().groupChildren)) }
}
