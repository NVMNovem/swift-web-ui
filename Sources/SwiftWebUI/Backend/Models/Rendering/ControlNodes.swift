//
//  ControlNodes.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

public struct ButtonNode {
    public let label: ViewNode
    public let action: ActionIntent?

    public init(label: ViewNode, action: ActionIntent?) {
        self.label = label
        self.action = action
    }
}

public struct LinkNode {
    public let destination: String
    public let label: ViewNode
    public let usesPlainTextLabel: Bool

    public init(destination: String, label: ViewNode, usesPlainTextLabel: Bool) {
        self.destination = destination
        self.label = label
        self.usesPlainTextLabel = usesPlainTextLabel
    }
}

public struct ImageNode {
    public let source: String
    public let alternativeText: String

    public init(source: String, alternativeText: String) {
        self.source = source
        self.alternativeText = alternativeText
    }
}

public struct InputNode {
    public init() {}
}

public struct TextAreaNode {
    public init() {}
}

public enum ActionIntent {
    case closure(() -> Void)
    case setState(ClientStateMutation)
}
