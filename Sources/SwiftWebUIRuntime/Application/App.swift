//
//  App.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

#if arch(wasm32)
import JavaScriptEventLoop
#endif

/// The entry point of a SwiftWebUI application that runs in the browser.
///
/// Mark one type with `@main` and describe what the page shows:
///
/// ```swift
/// import SwiftWebUI
/// import SwiftWebUIRuntime
///
/// @main
/// struct ShopApp: App {
///     var body: some Scene {
///         Page {
///             RootView()
///         }
///         .stylesheet(.external("styles.css"))
///     }
/// }
/// ```
///
/// This is SwiftUI's `App`, with ``Page`` standing where `WindowGroup` does: a browser
/// tab shows one document, so the scene is a page rather than a window.
///
/// ## What `main()` does
///
/// The `main()` this protocol supplies does the three things every browser application
/// otherwise writes by hand, in this order:
///
/// 1. installs the JavaScript event loop as Swift Concurrency's global executor, without
///    which an `await` never resumes in the browser. Under Embedded Swift it also
///    makes that event loop the main actor's executor, and the bundle carries the
///    JavaScriptKit exports and concurrency runtime functions Embedded Swift leaves
///    out, so an Embedded application needs nothing of its own for either;
/// 2. creates the application with ``init()``;
/// 3. mounts the scene from ``body``.
///
/// Because the executor is installed before ``init()`` runs, an application may start
/// asynchronous work there with `Task { … }`.
///
/// `main()` is only executable in a WebAssembly browser build. Describing an application
/// — creating it and reading its ``body`` — works on any platform, which is what lets a
/// host test inspect the scene.
public protocol App {
    /// The scene this application shows.
    associatedtype Body: Scene

    /// Creates the application. Called once, by ``main()``.
    init()

    /// What the application shows.
    var body: Body { get }
}

public extension App {
    /// Starts the application: installs the JavaScript event loop, creates the
    /// application and mounts its scene.
    static func main() {
        #if arch(wasm32)
        JavaScriptEventLoop.installGlobalExecutor()
        #if hasFeature(Embedded)
        // The main actor too, or it never runs: see `EmbeddedExecutors`.
        EmbeddedExecutors.install()
        #endif
        #endif
        Self().body._mountScene()
    }
}
