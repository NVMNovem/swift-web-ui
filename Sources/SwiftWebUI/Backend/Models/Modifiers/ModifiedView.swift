//
//  ModifiedView.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public struct ModifiedView<Content: View>: View {
    public typealias Body = AnyView

    var content: Content
    var modifiers: [ViewModifierData]

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
