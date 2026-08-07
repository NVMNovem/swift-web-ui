//
//  Image.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public struct Image: View {
    public typealias Body = Never
    public let source: String
    public let alt: String
    public init(_ source: String, alt: String = "") { self.source = source; self.alt = alt }
    public var body: Never { fatalError("Image primitive body unavailable") }
    public func makeViewNode(in context: ViewContext) -> ViewNode { .image(.init(source: source, alternativeText: alt)) }
}
