//
//  OptionalView.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

public struct OptionalView<Content: View>: View {
    public typealias Body = Never
    public let content: Content?
    public init(_ content: Content?) { self.content = content }
    public var body: Never { fatalError("OptionalView primitive body unavailable") }
    public func makeViewNode() -> ViewNode { content?.makeViewNode() ?? .empty }
}
