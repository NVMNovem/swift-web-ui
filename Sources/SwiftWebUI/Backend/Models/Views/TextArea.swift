//
//  TextArea.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 25/06/2026.
//

public struct TextArea: View {
    public typealias Body = Never
    public init() {}
    public var body: Never { fatalError("TextArea primitive body unavailable") }
    public func makeViewNode(in context: ViewContext) -> ViewNode { .textArea(.init()) }
}
