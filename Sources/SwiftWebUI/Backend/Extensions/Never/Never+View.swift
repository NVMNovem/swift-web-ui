//
//  Never+View.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

extension Never: View {
    public typealias Body = Never

    public var body: Never {
        fatalError("Never has no body")
    }

    public func makeViewNode(in context: ViewContext) -> ViewNode {
        fatalError("Never cannot be lowered")
    }
}
