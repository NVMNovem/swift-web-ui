//
//  Button.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public struct Button: View {
    public typealias Body = Never
    public let label: String
    public let action: (() -> Void)?

    public init(_ label: String, action: (() -> Void)? = nil) {
        self.label = label
        self.action = action
    }

    public var body: Never { fatalError("Button primitive body unavailable") }
    public func makeViewNode(in context: ViewContext) -> ViewNode {
        .button(.init(label: Text(label).makeViewNode(in: .detached), action: action.map(ActionIntent.closure)))
    }
}
