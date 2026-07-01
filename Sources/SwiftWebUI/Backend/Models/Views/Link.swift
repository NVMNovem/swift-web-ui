//
//  Link.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

/// A browser link that renders an HTML anchor.
///
/// Use the string initializer for simple links and the content initializer when
/// the anchor should wrap nested SwiftWebUI views.
public struct Link: View {
    public typealias Body = AnyView

    var textLabel: String?
    var destination: String
    var content: AnyView

    public init(_ label: String, destination: String) {
        self.textLabel = label
        self.destination = destination
        self.content = AnyView(EmptyView())
    }

    public init<Content: View>(
        destination: String,
        @ViewBuilder content: () -> Content
    ) {
        self.textLabel = nil
        self.destination = destination
        self.content = AnyView(content())
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
