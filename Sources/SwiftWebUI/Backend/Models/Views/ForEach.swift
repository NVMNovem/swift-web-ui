//
//  ForEach.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

public struct ForEach<Data: Sequence, Content: View>: View {
    public typealias Body = Never
    public let data: Data
    public let content: (Data.Element) -> Content

    public init(
        _ data: Data,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.content = content
    }

    public var body: Never { fatalError("ForEach primitive body unavailable") }

    public func makeViewNode() -> ViewNode {
        var nodes: [ViewNode] = []
        for element in data {
            nodes.append(content(element).makeViewNode())
        }
        return .group(nodes)
    }
}
