//
//  SwiftWebUIRuntime.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

@_spi(Runtime) @_spi(Rendering) import SwiftWebUI

#if arch(wasm32)
nonisolated(unsafe) private var mountedRoot: AnyObject?

/// Mounts a SwiftWebUI view in the browser element with the supplied identifier.
///
/// The runtime supports one mounted root and incrementally reconciles it after
/// each observed `State` mutation.
public func mount<Content: View>(
    _ view: Content,
    in elementID: String,
    configuration: SwiftWebUIRuntimeConfiguration = .init()
) {
    guard let backend = JavaScriptDOMBackend() else {
        preconditionFailure("SwiftWebUIRuntime requires a browser document")
    }
    guard let container = backend.element(withID: elementID) else {
        preconditionFailure("SwiftWebUIRuntime could not find #\(elementID)")
    }

    let root = MountedRoot(
        container: container,
        backend: backend,
        configuration: configuration,
        build: { ViewNodeToWebNodeLowerer().lower(view.makeViewNode()) }
    )
    mountedRoot = root
    root.start()
}
#else
/// Mounts a SwiftWebUI view in a browser DOM element.
///
/// This API is only executable when compiled for WebAssembly.
public func mount<Content: View>(
    _ view: Content,
    in elementID: String,
    configuration: SwiftWebUIRuntimeConfiguration = .init()
) {
    preconditionFailure("SwiftWebUIRuntime.mount requires a WebAssembly browser build")
}
#endif
