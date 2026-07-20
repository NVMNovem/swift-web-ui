//
//  ViewRendererProtocol.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 07/07/2026.
//

/// A renderer with a statically specialized SwiftWebUI entry point.
public protocol ViewRendererProtocol {
    associatedtype Output

    func render<Content: View>(_ view: Content) -> Output
}
