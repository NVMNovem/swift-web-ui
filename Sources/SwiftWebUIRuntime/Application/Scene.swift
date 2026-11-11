//
//  Scene.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

/// A part of an application's user interface that the runtime knows how to show.
///
/// ``Page`` is the scene SwiftWebUI provides. An ``App`` returns one from its `body`.
public protocol Scene {
    /// Shows this scene in the browser document.
    ///
    /// Called by ``App/main()``. It is a requirement only so that the runtime can reach
    /// the concrete scene without an existential, which keeps the entry point within
    /// what Embedded Swift can compile. Applications do not call it.
    func _mountScene()
}
