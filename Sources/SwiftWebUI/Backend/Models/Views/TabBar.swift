//
//  TabBar.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 25/06/2026.
//

/// A selection-only tab control.
///
/// Use `TabBar` for navigation tabs, segmented controls, filters, and similar
/// controls that do not own matching content panels.
public struct TabBar<Value: Hashable>: View {
    public typealias Body = AnyView

    var selection: Value
    var clientState: ClientStateBinding?
    var tabs: [Tab<Value>]

    public init(
        selection: Value,
        @TabBuilder<Value> tabs: () -> [Tab<Value>]
    ) {
        self.selection = selection
        self.clientState = nil
        self.tabs = tabs()
    }

    public init(
        selection: Binding<Value>,
        @TabBuilder<Value> tabs: () -> [Tab<Value>]
    ) {
        self.selection = selection.wrappedValue
        self.clientState = selection.clientState
        self.tabs = tabs()
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
