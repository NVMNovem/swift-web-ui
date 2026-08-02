//
//  Tab.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 25/06/2026.
//

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

extension Tab {
    var node: TabItemNode { .init(value: valueNode, label: label, content: content) }
}
