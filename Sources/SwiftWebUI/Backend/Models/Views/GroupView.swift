//
//  GroupView.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

/// A layout-neutral composition container.
///
/// An unmodified group renders transparently. A modified group renders an
/// implicit `div` so attributes and generated classes have an element target.
public struct Group<Content: View>: View {
    public typealias Body = AnyView

    var content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}

/// A compatibility carrier for multiple result-builder child views.
///
/// Prefer ``Group`` in user-facing code.
public struct GroupView: View {
    public typealias Body = AnyView

    var children: [AnyView]

    public init(_ children: [AnyView]) {
        self.children = children
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
