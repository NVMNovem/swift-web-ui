//
//  ViewRendererProtocol.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 07/07/2026.
//

/// A renderer that lowers a SwiftWebUI ``View`` into a renderer-owned output.
///
/// The protocol keeps the user-facing ``View`` API independent from a concrete
/// output format. Current browser HTML rendering is provided by ``HTMLRenderer``.
public protocol ViewRendererProtocol {
    associatedtype Output

    /// Renders a SwiftWebUI view into this renderer's output type.
    func render<V: View>(_ view: V) -> Output
}
