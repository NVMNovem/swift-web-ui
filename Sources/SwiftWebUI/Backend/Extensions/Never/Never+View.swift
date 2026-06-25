//
//  Never+View.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

extension Never: View {
    public typealias Body = AnyView

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
