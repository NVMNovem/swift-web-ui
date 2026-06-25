//
//  Tab.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 25/06/2026.
//

public struct Tab<Value: Hashable>: View {
    public typealias Body = AnyView

    var value: Value
    var label: AnyView

    public init(_ title: String, value: Value) {
        self.value = value
        self.label = AnyView(Text(title))
    }

    public init<Label: View>(value: Value, @ViewBuilder label: () -> Label) {
        self.value = value
        self.label = AnyView(label())
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
