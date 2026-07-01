//
//  Button.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

/// A button control that renders an HTML `button` element.
///
/// The closure initializer is retained as API surface, but arbitrary Swift
/// closures are not translated to JavaScript. Use generated client-state
/// modifiers such as `.set(_:to:)` for supported browser-side behavior.
public struct Button: View {
    public typealias Body = AnyView

    var label: String
    var action: (() -> Void)?

    public init(_ label: String, action: (() -> Void)? = nil) {
        self.label = label
        self.action = action
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
