//
//  Spacer.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

/// A flexible layout spacer for stack-like layouts.
public struct Spacer: View {
    public typealias Body = AnyView

    public init() {}

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
