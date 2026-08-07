//
//  ArrayView.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

public struct ArrayView<Content: View>: View {
    public typealias Body = Never
    public let content: [Content]
    public init(_ content: [Content]) { self.content = content }
    public var body: Never { fatalError("ArrayView primitive body unavailable") }
    public func makeViewNode(in context: ViewContext) -> ViewNode {
        var nodes: [ViewNode] = []
        nodes.reserveCapacity(content.count)
        for (index, element) in content.enumerated() {
            nodes.append(element.makeViewNode(in: context.child(index)))
        }
        return .group(nodes)
    }
}
