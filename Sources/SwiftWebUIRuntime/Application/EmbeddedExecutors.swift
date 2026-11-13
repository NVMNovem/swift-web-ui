//
//  EmbeddedExecutors.swift
//  swift-web-ui
//

#if hasFeature(Embedded) && arch(wasm32)
import JavaScriptEventLoop
@_spi(ExperimentalCustomExecutors) import _Concurrency

/// The executors Swift Concurrency runs on under Embedded Swift: JavaScriptKit's
/// event loop, for the main actor and for everything else.
///
/// Under Embedded Swift, JavaScriptKit's `installGlobalExecutor()` installs only
/// its enqueue hooks. Without an executor factory the main actor runs on Embedded
/// Swift's own cooperative run loop, which nothing drives in a browser, so a
/// `Task` started from `init()`, or anything else on the main actor, never runs.
/// JavaScriptKit has a factory of its own, but declares its conformance as SPI
/// that a client cannot use, so this one forwards to its public `enqueue`.
///
/// Installed by ``App/main()`` before the application is created.
enum EmbeddedExecutors: ExecutorFactory {
    static let loop = EventLoopExecutor()

    static var mainExecutor: any MainExecutor { loop }
    static var defaultExecutor: any TaskExecutor { loop }

    static func install() {
        _createExecutors(factory: EmbeddedExecutors.self)
    }
}

final class EventLoopExecutor: MainExecutor, TaskExecutor {
    func enqueue(_ job: consuming ExecutorJob) {
        JavaScriptEventLoop.shared.enqueue(job)
    }

    /// The browser's event loop runs on its own; there is nothing to drive.
    func run() throws {}

    func runUntil(_ condition: () -> Bool) throws {}

    func stop() {}

    func checkIsolated() {}
}
#endif
