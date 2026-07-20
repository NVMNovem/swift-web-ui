//
//  TabBar.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 25/06/2026.
//

public struct TabBar<Value: Hashable>: View {
    public typealias Body = Never
    public let selection: ClientValue
    public let state: ClientStateBinding?
    public let tabs: [Tab<Value>]
    private init(selection: ClientValue, state: ClientStateBinding?, tabs: [Tab<Value>]) { self.selection = selection; self.state = state; self.tabs = tabs }
    public var body: Never { fatalError("TabBar primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .tabControl(.init(kind: .bar, selection: selection, state: state, tabs: tabs.map(\.node))) }
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
