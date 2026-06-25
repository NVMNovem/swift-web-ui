//
//  Text.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public struct Text: View {
    public typealias Body = AnyView

    var content: String

    public init(_ content: String) {
        self.content = content
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
