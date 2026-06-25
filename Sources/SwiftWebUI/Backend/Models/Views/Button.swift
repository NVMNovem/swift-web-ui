//
//  Button.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

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
