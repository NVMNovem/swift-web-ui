import SwiftCSS

/// Concrete renderer-neutral output from the SwiftWebUI DSL.
public indirect enum ViewNode {
    case empty
    case text(TextNode)
    case container(ContainerNode)
    case button(ButtonNode)
    case link(LinkNode)
    case image(ImageNode)
    case input(InputNode)
    case textArea(TextAreaNode)
    case spacer
    case tabControl(TabControlNode)
    case group([ViewNode])
    case modified(ModifiedNode)
}

public struct TextNode {
    public let content: String
    public let semanticRole: SemanticRole

    public init(content: String, semanticRole: SemanticRole) {
        self.content = content
        self.semanticRole = semanticRole
    }
}

public struct ContainerNode {
    public let kind: ContainerKind
    public let children: [ViewNode]

    public init(kind: ContainerKind, children: [ViewNode]) {
        self.kind = kind
        self.children = children
    }
}

public enum ContainerKind {
    case group
    case vertical(alignment: Alignment, spacing: SwiftCSS.Length?)
    case horizontal(alignment: Alignment, spacing: SwiftCSS.Length?)
    case grid(spacing: SwiftCSS.Length?)
    case div
    case article
    case section
    case form
    case label(text: String?)
    case footer
    case template(name: String)
}

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

public struct ModifiedNode {
    public let content: ViewNode
    public let modifiers: [ViewModifierNode]

    public init(content: ViewNode, modifiers: [ViewModifierNode]) {
        self.content = content
        self.modifiers = modifiers
    }
}

public enum ActionIntent {
    case closure(() -> Void)
    case setState(ClientStateMutation)
}

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
