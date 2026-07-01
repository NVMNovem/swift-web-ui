//
//  AnyView.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftHTML

/// A type-erased SwiftWebUI view.
public struct AnyView: View {
    public typealias Body = AnyView

    let renderStorage: (inout RenderContext) -> [any SwiftHTML.HTMLNode]

    public init<V: View>(_ view: V) {
        renderStorage = { context in
            view.renderSwiftHTML(context: &context)
        }
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
