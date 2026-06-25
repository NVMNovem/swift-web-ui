//
//  Link.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public struct Link: View {
    public typealias Body = AnyView

    var label: String
    var destination: String

    public init(_ label: String, destination: String) {
        self.label = label
        self.destination = destination
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
