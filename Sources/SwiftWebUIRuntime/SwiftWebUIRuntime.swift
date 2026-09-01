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
    mount(view, in: elementID, resources: .init(), configuration: configuration)
}

/// Mounts a SwiftWebUI view after installing application stylesheet resources.
///
/// External stylesheet URLs are preserved for browser-relative resolution. Inline
/// stylesheets are inserted as authored. The runtime currently owns resources at
/// its single mounted application root, independently of DOM reconciliation.
public func mount<Content: View>(
    _ view: Content,
    in elementID: String,
    resources: RuntimeResources,
    configuration: SwiftWebUIRuntimeConfiguration = .init()
) {
    guard let backend = JavaScriptDOMBackend() else {
        preconditionFailure("SwiftWebUIRuntime requires a browser document")
    }
    guard let container = backend.element(withID: elementID) else {
        preconditionFailure("SwiftWebUIRuntime could not find #\(elementID)")
    }

    let installedResources: InstalledRuntimeResources<JavaScriptDOMBackend.Node>
    do {
        installedResources = try RuntimeStylesheetInstaller(backend: backend)
            .install(resources.withRuntimeStylesheets())
    } catch {
        print("[SwiftWebUIRuntime] resource installation failed: \(error)")
        return
    }

    let root = MountedRoot(
        container: container,
        backend: backend,
        configuration: configuration,
        installedResources: installedResources,
        build: { ViewNodeToWebNodeLowerer().lowerView(view.makeViewNode()) }
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

/// Mounts a SwiftWebUI view with application stylesheet resources.
///
/// This API is only executable when compiled for WebAssembly.
public func mount<Content: View>(
    _ view: Content,
    in elementID: String,
    resources: RuntimeResources,
    configuration: SwiftWebUIRuntimeConfiguration = .init()
) {
    preconditionFailure("SwiftWebUIRuntime.mount requires a WebAssembly browser build")
}
#endif
