//
//  View.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

/// A declarative SwiftWebUI component that renders to browser HTML and resources.
///
/// Conform to `View` by returning other SwiftWebUI views from ``body``. SwiftWebUI
/// renderers lower the resulting tree into renderer-owned output.
public protocol View {
    associatedtype Body: View

    /// The content and behavior of the view.
    @ViewBuilder var body: Body { get }
}
