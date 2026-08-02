//
//  Label.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 01/07/2026.
//

public struct Label<Content: View>: View {
    public typealias Body = Never
    public let textLabel: String?
    public let content: Content

    public init(_ textLabel: String) where Content == EmptyView {
        self.textLabel = textLabel
        self.content = EmptyView()
    }

    public init(@ViewBuilder content: () -> Content) {
        self.textLabel = nil
        self.content = content()
    }

    public var body: Never { fatalError("Label primitive body unavailable") }
    public func makeViewNode() -> ViewNode {
        .container(.init(kind: .label(text: textLabel), children: content.makeViewNode().groupChildren))
    }
}
