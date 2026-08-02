//
//  TabControlNode.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

public struct TabControlNode {
    public enum Kind: Equatable, Sendable {
        case bar
        case view
    }

    public let kind: Kind
    public let selection: ClientValue
    public let state: ClientStateBinding?
    public let tabs: [TabItemNode]

    public init(
        kind: Kind,
        selection: ClientValue,
        state: ClientStateBinding?,
        tabs: [TabItemNode]
    ) {
        self.kind = kind
        self.selection = selection
        self.state = state
        self.tabs = tabs
    }
}

public struct TabItemNode {
    public let value: ClientValue
    public let label: ViewNode
    public let content: ViewNode

    public init(value: ClientValue, label: ViewNode, content: ViewNode) {
        self.value = value
        self.label = label
        self.content = content
    }
}
