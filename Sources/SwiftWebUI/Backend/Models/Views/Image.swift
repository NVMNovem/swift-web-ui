//
//  Image.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public struct Image: View {
    public typealias Body = AnyView

    var source: String
    var alt: String

    public init(_ source: String, alt: String = "") {
        self.source = source
        self.alt = alt
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
