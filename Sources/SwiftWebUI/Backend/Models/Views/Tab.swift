//
//  Tab.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 25/06/2026.
//

/// A tab item used by ``TabBar`` and ``TabView``.
///
/// A tab has a selection value, label content, and optional panel content.
public struct Tab<Value: Hashable>: View {
    public typealias Body = AnyView

    var value: Value
    var label: AnyView
    var content: AnyView

    public init(
        _ title: String,
        value: Value
    ) {
        self.value = value
        self.label = AnyView(Text(title))
        self.content = AnyView(EmptyView())
    }

    public init<Content: View>(
        _ title: String,
        value: Value,
        @ViewBuilder content: () -> Content
    ) {
        self.value = value
        self.label = AnyView(Text(title))
        self.content = AnyView(content())
    }

    public init<Label: View, Content: View>(
        value: Value,
        @ViewBuilder label: () -> Label,
        @ViewBuilder content: () -> Content
    ) {
        self.value = value
        self.label = AnyView(label())
        self.content = AnyView(content())
    }

    public init<Label: View>(
        value: Value,
        @ViewBuilder label: () -> Label
    ) {
        self.value = value
        self.label = AnyView(label())
        self.content = AnyView(EmptyView())
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
