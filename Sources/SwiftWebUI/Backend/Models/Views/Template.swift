//
//  Template.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 05/07/2026.
//

public struct Template<Content: View>: View {
    public typealias Body = Never
    public let name: String
    public let content: Content
    public init(_ name: String, @ViewBuilder content: () -> Content) { self.name = name; self.content = content() }
    public var body: Never { fatalError("Template primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .container(.init(kind: .template(name: name), children: content.makeViewNode().groupChildren)) }
}
