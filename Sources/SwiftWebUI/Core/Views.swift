import SwiftCSS

public struct EmptyView: View {
    public typealias Body = Never
    public init() {}
    public var body: Never { fatalError("EmptyView primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .empty }
}

public struct Text: View {
    public typealias Body = Never
    public let content: String
    public let semanticRole: SemanticRole

    public init(_ content: String, semanticRole: SemanticRole = .span) {
        self.content = content
        self.semanticRole = semanticRole
    }

    public func semanticRole(_ role: SemanticRole) -> Text {
        Text(content, semanticRole: role)
    }

    public var body: Never { fatalError("Text primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .text(.init(content: content, semanticRole: semanticRole)) }
}

public struct Group<Content: View>: View {
    public typealias Body = Never
    public let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: Never { fatalError("Group primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .container(.init(kind: .group, children: content.makeViewNode().groupChildren)) }
}

public struct VStack<Content: View>: View {
    public typealias Body = Never
    public let alignment: Alignment
    public let spacing: SwiftCSS.Length?
    public let content: Content

    public init(
        alignment: Alignment = .center,
        spacing: SwiftCSS.Length? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    public var body: Never { fatalError("VStack primitive body unavailable") }
    public func makeViewNode() -> ViewNode {
        .container(.init(kind: .vertical(alignment: alignment, spacing: spacing), children: content.makeViewNode().groupChildren))
    }
}

public struct HStack<Content: View>: View {
    public typealias Body = Never
    public let alignment: Alignment
    public let spacing: SwiftCSS.Length?
    public let content: Content

    public init(
        alignment: Alignment = .center,
        spacing: SwiftCSS.Length? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    public var body: Never { fatalError("HStack primitive body unavailable") }
    public func makeViewNode() -> ViewNode {
        .container(.init(kind: .horizontal(alignment: alignment, spacing: spacing), children: content.makeViewNode().groupChildren))
    }
}

public struct Grid<Content: View>: View {
    public typealias Body = Never
    public let spacing: SwiftCSS.Length?
    public let content: Content

    public init(spacing: SwiftCSS.Length? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: Never { fatalError("Grid primitive body unavailable") }
    public func makeViewNode() -> ViewNode {
        .container(.init(kind: .grid(spacing: spacing), children: content.makeViewNode().groupChildren))
    }
}

public struct Div<Content: View>: View {
    public typealias Body = Never
    public let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: Never { fatalError("Div primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .container(.init(kind: .div, children: content.makeViewNode().groupChildren)) }
}

public struct Article<Content: View>: View {
    public typealias Body = Never
    public let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: Never { fatalError("Article primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .container(.init(kind: .article, children: content.makeViewNode().groupChildren)) }
}

public struct Section<Content: View>: View {
    public typealias Body = Never
    public let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: Never { fatalError("Section primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .container(.init(kind: .section, children: content.makeViewNode().groupChildren)) }
}

public struct Form<Content: View>: View {
    public typealias Body = Never
    public let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: Never { fatalError("Form primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .container(.init(kind: .form, children: content.makeViewNode().groupChildren)) }
}

public struct Footer<Content: View>: View {
    public typealias Body = Never
    public let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: Never { fatalError("Footer primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .container(.init(kind: .footer, children: content.makeViewNode().groupChildren)) }
}

public struct Template<Content: View>: View {
    public typealias Body = Never
    public let name: String
    public let content: Content
    public init(_ name: String, @ViewBuilder content: () -> Content) { self.name = name; self.content = content() }
    public var body: Never { fatalError("Template primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .container(.init(kind: .template(name: name), children: content.makeViewNode().groupChildren)) }
}

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

public struct Link: View {
    public typealias Body = Never
    public let destination: String
    public let label: ViewNode
    public let usesPlainTextLabel: Bool

    public init(_ label: String, destination: String) {
        self.destination = destination
        self.label = Text(label).makeViewNode()
        self.usesPlainTextLabel = true
    }

    public init<Content: View>(destination: String, @ViewBuilder content: () -> Content) {
        self.destination = destination
        self.label = content().makeViewNode()
        self.usesPlainTextLabel = false
    }

    public var body: Never { fatalError("Link primitive body unavailable") }
    public func makeViewNode() -> ViewNode {
        .link(.init(destination: destination, label: label, usesPlainTextLabel: usesPlainTextLabel))
    }
}

public struct Button: View {
    public typealias Body = Never
    public let label: String
    public let action: (() -> Void)?

    public init(_ label: String, action: (() -> Void)? = nil) {
        self.label = label
        self.action = action
    }

    public var body: Never { fatalError("Button primitive body unavailable") }
    public func makeViewNode() -> ViewNode {
        .button(.init(label: Text(label).makeViewNode(), action: action.map(ActionIntent.closure)))
    }
}

public struct Image: View {
    public typealias Body = Never
    public let source: String
    public let alt: String
    public init(_ source: String, alt: String = "") { self.source = source; self.alt = alt }
    public var body: Never { fatalError("Image primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .image(.init(source: source, alternativeText: alt)) }
}

public struct Input: View {
    public typealias Body = Never
    public init() {}
    public var body: Never { fatalError("Input primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .input(.init()) }
}

public struct TextArea: View {
    public typealias Body = Never
    public init() {}
    public var body: Never { fatalError("TextArea primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .textArea(.init()) }
}

public struct Spacer: View {
    public typealias Body = Never
    public init() {}
    public var body: Never { fatalError("Spacer primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .spacer }
}

@resultBuilder
public enum TabBuilder<Value: Hashable> {
    public static func buildExpression(_ expression: Tab<Value>) -> [Tab<Value>] { [expression] }
    public static func buildExpression(_ expressions: [Tab<Value>]) -> [Tab<Value>] { expressions }
    public static func buildBlock() -> [Tab<Value>] { [] }
    public static func buildBlock(_ components: [Tab<Value>]...) -> [Tab<Value>] { components.flatMap { $0 } }
    public static func buildOptional(_ component: [Tab<Value>]?) -> [Tab<Value>] { component ?? [] }
    public static func buildEither(first component: [Tab<Value>]) -> [Tab<Value>] { component }
    public static func buildEither(second component: [Tab<Value>]) -> [Tab<Value>] { component }
    public static func buildArray(_ components: [[Tab<Value>]]) -> [Tab<Value>] { components.flatMap { $0 } }
}

public struct Tab<Value: Hashable>: View {
    public typealias Body = Never
    public let value: Value
    public let valueNode: ClientValue
    public let label: ViewNode
    public let content: ViewNode

    private init(value: Value, valueNode: ClientValue, label: ViewNode, content: ViewNode) {
        self.value = value
        self.valueNode = valueNode
        self.label = label
        self.content = content
    }

    public var body: Never { fatalError("Tab primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .button(.init(label: label, action: nil)) }
}

public extension Tab where Value: ClientStateValue {
    init(_ title: String, value: Value) { self.init(value: value, valueNode: value.clientValue, label: Text(title).makeViewNode(), content: .empty) }
    init<Content: View>(_ title: String, value: Value, @ViewBuilder content: () -> Content) { self.init(value: value, valueNode: value.clientValue, label: Text(title).makeViewNode(), content: content().makeViewNode()) }
    init<LabelContent: View, Content: View>(value: Value, @ViewBuilder label: () -> LabelContent, @ViewBuilder content: () -> Content) { self.init(value: value, valueNode: value.clientValue, label: label().makeViewNode(), content: content().makeViewNode()) }
    init<LabelContent: View>(value: Value, @ViewBuilder label: () -> LabelContent) { self.init(value: value, valueNode: value.clientValue, label: label().makeViewNode(), content: .empty) }
}

public extension Tab where Value: RawRepresentable, Value.RawValue == String {
    init(_ title: String, value: Value) { self.init(value: value, valueNode: .string(value.rawValue), label: Text(title).makeViewNode(), content: .empty) }
    init<Content: View>(_ title: String, value: Value, @ViewBuilder content: () -> Content) { self.init(value: value, valueNode: .string(value.rawValue), label: Text(title).makeViewNode(), content: content().makeViewNode()) }
    init<LabelContent: View, Content: View>(value: Value, @ViewBuilder label: () -> LabelContent, @ViewBuilder content: () -> Content) { self.init(value: value, valueNode: .string(value.rawValue), label: label().makeViewNode(), content: content().makeViewNode()) }
    init<LabelContent: View>(value: Value, @ViewBuilder label: () -> LabelContent) { self.init(value: value, valueNode: .string(value.rawValue), label: label().makeViewNode(), content: .empty) }
}

public extension Tab where Value: RawRepresentable, Value.RawValue == Int {
    init(_ title: String, value: Value) { self.init(value: value, valueNode: .integer(value.rawValue), label: Text(title).makeViewNode(), content: .empty) }
    init<Content: View>(_ title: String, value: Value, @ViewBuilder content: () -> Content) { self.init(value: value, valueNode: .integer(value.rawValue), label: Text(title).makeViewNode(), content: content().makeViewNode()) }
    init<LabelContent: View, Content: View>(value: Value, @ViewBuilder label: () -> LabelContent, @ViewBuilder content: () -> Content) { self.init(value: value, valueNode: .integer(value.rawValue), label: label().makeViewNode(), content: content().makeViewNode()) }
    init<LabelContent: View>(value: Value, @ViewBuilder label: () -> LabelContent) { self.init(value: value, valueNode: .integer(value.rawValue), label: label().makeViewNode(), content: .empty) }
}

public struct TabBar<Value: Hashable>: View {
    public typealias Body = Never
    public let selection: ClientValue
    public let state: ClientStateBinding?
    public let tabs: [Tab<Value>]
    private init(selection: ClientValue, state: ClientStateBinding?, tabs: [Tab<Value>]) { self.selection = selection; self.state = state; self.tabs = tabs }
    public var body: Never { fatalError("TabBar primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .tabControl(.init(kind: .bar, selection: selection, state: state, tabs: tabs.map(\.node))) }
}

public struct TabView<Value: Hashable>: View {
    public typealias Body = Never
    public let selection: ClientValue
    public let state: ClientStateBinding?
    public let tabs: [Tab<Value>]
    private init(selection: ClientValue, state: ClientStateBinding?, tabs: [Tab<Value>]) { self.selection = selection; self.state = state; self.tabs = tabs }
    public var body: Never { fatalError("TabView primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .tabControl(.init(kind: .view, selection: selection, state: state, tabs: tabs.map(\.node))) }
}

public extension TabBar where Value: ClientStateValue {
    init(selection: Value, @TabBuilder<Value> tabs: () -> [Tab<Value>]) { self.init(selection: selection.clientValue, state: nil, tabs: tabs()) }
    init(selection: Binding<Value>, @TabBuilder<Value> tabs: () -> [Tab<Value>]) { let value = selection.wrappedValue.clientValue; self.init(selection: value, state: selection.binding(value), tabs: tabs()) }
}

public extension TabBar where Value: RawRepresentable, Value.RawValue == String {
    init(selection: Value, @TabBuilder<Value> tabs: () -> [Tab<Value>]) { self.init(selection: .string(selection.rawValue), state: nil, tabs: tabs()) }
    init(selection: Binding<Value>, @TabBuilder<Value> tabs: () -> [Tab<Value>]) { let value = ClientValue.string(selection.wrappedValue.rawValue); self.init(selection: value, state: selection.binding(value), tabs: tabs()) }
}

public extension TabBar where Value: RawRepresentable, Value.RawValue == Int {
    init(selection: Value, @TabBuilder<Value> tabs: () -> [Tab<Value>]) { self.init(selection: .integer(selection.rawValue), state: nil, tabs: tabs()) }
    init(selection: Binding<Value>, @TabBuilder<Value> tabs: () -> [Tab<Value>]) { let value = ClientValue.integer(selection.wrappedValue.rawValue); self.init(selection: value, state: selection.binding(value), tabs: tabs()) }
}

public extension TabView where Value: ClientStateValue {
    init(selection: Value, @TabBuilder<Value> tabs: () -> [Tab<Value>]) { self.init(selection: selection.clientValue, state: nil, tabs: tabs()) }
    init(selection: Binding<Value>, @TabBuilder<Value> tabs: () -> [Tab<Value>]) { let value = selection.wrappedValue.clientValue; self.init(selection: value, state: selection.binding(value), tabs: tabs()) }
}

public extension TabView where Value: RawRepresentable, Value.RawValue == String {
    init(selection: Value, @TabBuilder<Value> tabs: () -> [Tab<Value>]) { self.init(selection: .string(selection.rawValue), state: nil, tabs: tabs()) }
    init(selection: Binding<Value>, @TabBuilder<Value> tabs: () -> [Tab<Value>]) { let value = ClientValue.string(selection.wrappedValue.rawValue); self.init(selection: value, state: selection.binding(value), tabs: tabs()) }
}

public extension TabView where Value: RawRepresentable, Value.RawValue == Int {
    init(selection: Value, @TabBuilder<Value> tabs: () -> [Tab<Value>]) { self.init(selection: .integer(selection.rawValue), state: nil, tabs: tabs()) }
    init(selection: Binding<Value>, @TabBuilder<Value> tabs: () -> [Tab<Value>]) { let value = ClientValue.integer(selection.wrappedValue.rawValue); self.init(selection: value, state: selection.binding(value), tabs: tabs()) }
}

private extension Tab {
    var node: TabItemNode { .init(value: valueNode, label: label, content: content) }
}

private extension Binding {
    func binding(_ initialValue: ClientValue) -> ClientStateBinding? {
        stateIdentity.map { .init(target: .state($0), initialValue: initialValue) }
    }
}

private extension ViewNode {
    var groupChildren: [ViewNode] {
        switch self {
        case .empty: []
        case .group(let children): children
        default: [self]
        }
    }
}
