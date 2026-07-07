//
//  Template.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 05/07/2026.
//

/// Defines reusable browser template markup for generated runtime behavior.
///
/// `Template` renders a real HTML `template` element and marks it with
/// `data-swiftwebui-template` so behaviors such as ``RemoteList`` can clone it.
public struct Template<Content: View>: View {
    public typealias Body = AnyView

    var name: String
    var content: Content

    public init(_ name: String, @ViewBuilder content: () -> Content) {
        self.name = name
        self.content = content()
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
