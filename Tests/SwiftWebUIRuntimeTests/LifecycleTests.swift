//
//  LifecycleTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 13/11/2026.
//

import Foundation
import Testing
@_spi(Runtime) @_spi(Rendering) import SwiftWebUI
@testable import SwiftWebUIRuntime

// MARK: - Fixtures

private final class Log: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String] = []

    func append(_ entry: String) {
        lock.lock(); defer { lock.unlock() }
        storage.append(entry)
    }

    var entries: [String] {
        lock.lock(); defer { lock.unlock() }
        return storage
    }
}

private final class Shared<T> {
    var value: T
    init(_ value: T) { self.value = value }
}

private struct Appearing: View {
    let name: String
    let log: Log
    /// What the container held when the action ran.
    let container: FakeDOMNode?

    var body: some View {
        Text(name)
            .onAppear {
                log.append("appear \(name) mounted=\(container?.children.isEmpty == false)")
            }
            .onDisappear { log.append("disappear \(name)") }
    }
}

private struct Toggled: View {
    let shown: Shared<Bool>
    let log: Log
    let container: FakeDOMNode?

    var body: some View {
        VStack {
            if shown.value {
                Appearing(name: "a", log: log, container: container)
            }
            Text("always")
        }
    }
}

private struct Loader: View {
    let shown: Shared<Bool>
    let id: Shared<Int>
    let log: Log

    var body: some View {
        VStack {
            if shown.value {
                Text("loading")
                    .task(id: id.value) { [log, id = id.value] in
                        log.append("start \(id)")
                        while !Task.isCancelled {
                            await Task.yield()
                        }
                        log.append("cancelled \(id)")
                    }
            }
        }
    }
}

private struct Watching: View {
    let value: Shared<Int>
    let log: Log
    let initial: Bool

    var body: some View {
        Text(String(value.value))
            .onChange(of: value.value, initial: initial) { old, new in
                log.append("\(old)->\(new)")
            }
    }
}

private struct LoadsOnAppear: View {
    @State private var loaded = false

    var body: some View {
        Text(loaded ? "loaded" : "loading")
            .onAppear { loaded = true }
    }
}

// MARK: - Helpers

private func texts(_ node: FakeDOMNode) -> [String] {
    var found: [String] = []
    if let text = node.text { found.append(text) }
    for child in node.children { found.append(contentsOf: texts(child)) }
    return found
}

private func makeRoot<Content: View>(
    _ view: Content,
    backend: FakeDOMBackend
) -> MountedRoot<FakeDOMBackend> {
    MountedRoot(container: backend.root, backend: backend) {
        ViewNodeToWebNodeLowerer().lowerView(view.makeViewNode())
    }
}

/// Waits, briefly, for a task the runtime started to log `entry`.
private func eventually(_ log: Log, contains entry: String) async -> Bool {
    for _ in 0..<2_000 {
        if log.entries.contains(entry) { return true }
        try? await Task.sleep(nanoseconds: 1_000_000)
    }
    return false
}

// MARK: - Tests

extension RuntimeMountTests {
    @Suite struct LifecycleTests {

        @Test func onAppearRunsOnceAfterTheDOMShowsTheView() {
            let log = Log()
            let backend = FakeDOMBackend()
            let root = makeRoot(Appearing(name: "a", log: log, container: backend.root), backend: backend)
            defer { root.stop() }

            root.start()
            #expect(log.entries == ["appear a mounted=true"])

            root.invalidate()
            root.invalidate()
            #expect(log.entries == ["appear a mounted=true"])
        }

        @Test func removingABranchRunsOnDisappearAndShowingItAgainAppears() {
            let log = Log()
            let shown = Shared(true)
            let backend = FakeDOMBackend()
            let root = makeRoot(Toggled(shown: shown, log: log, container: backend.root), backend: backend)
            defer { root.stop() }

            root.start()
            shown.value = false
            root.invalidate()
            #expect(log.entries == ["appear a mounted=true", "disappear a"])
            #expect(texts(backend.root) == ["always"])

            shown.value = true
            root.invalidate()
            #expect(log.entries == ["appear a mounted=true", "disappear a", "appear a mounted=true"])
        }

        @Test func stoppingTheRootRunsOnDisappear() {
            let log = Log()
            let backend = FakeDOMBackend()
            let root = makeRoot(Appearing(name: "a", log: log, container: nil), backend: backend)

            root.start()
            root.stop()
            #expect(log.entries == ["appear a mounted=false", "disappear a"])
        }

        @Test func aStateWriteInOnAppearIsDrawnOnTheNextFrame() {
            let backend = FakeDOMBackend()
            let root = makeRoot(LoadsOnAppear(), backend: backend)
            defer { root.stop() }

            root.start()
            #expect(texts(backend.root) == ["loading"])
            #expect(backend.scheduled.count == 1)

            backend.runScheduledWork()
            #expect(texts(backend.root) == ["loaded"])
            #expect(backend.scheduled.isEmpty)
        }

        @Test func aTaskStartsOnAppearAndIsCancelledOnDisappear() async {
            let log = Log()
            let shown = Shared(true)
            let id = Shared(1)
            let backend = FakeDOMBackend()
            let root = makeRoot(Loader(shown: shown, id: id, log: log), backend: backend)
            defer { root.stop() }

            root.start()
            #expect(await eventually(log, contains: "start 1"))

            root.invalidate()
            shown.value = false
            root.invalidate()
            #expect(await eventually(log, contains: "cancelled 1"))
            #expect(log.entries.filter { $0.hasPrefix("start") } == ["start 1"])
        }

        @Test func aTaskRestartsWhenItsIDChanges() async {
            let log = Log()
            let id = Shared(1)
            let backend = FakeDOMBackend()
            let root = makeRoot(Loader(shown: Shared(true), id: id, log: log), backend: backend)

            root.start()
            #expect(await eventually(log, contains: "start 1"))

            id.value = 2
            root.invalidate()
            #expect(await eventually(log, contains: "cancelled 1"))
            #expect(await eventually(log, contains: "start 2"))

            root.stop()
            #expect(await eventually(log, contains: "cancelled 2"))
        }

        @Test func onChangeReportsTheOldAndNewValue() {
            let log = Log()
            let value = Shared(1)
            let backend = FakeDOMBackend()
            let root = makeRoot(Watching(value: value, log: log, initial: false), backend: backend)
            defer { root.stop() }

            root.start()
            #expect(log.entries.isEmpty)

            root.invalidate()
            #expect(log.entries.isEmpty)

            value.value = 2
            root.invalidate()
            value.value = 5
            root.invalidate()
            #expect(log.entries == ["1->2", "2->5"])
        }

        @Test func onChangeWithInitialAlsoRunsOnAppear() {
            let log = Log()
            let backend = FakeDOMBackend()
            let root = makeRoot(Watching(value: Shared(3), log: log, initial: true), backend: backend)
            defer { root.stop() }

            root.start()
            #expect(log.entries == ["3->3"])
        }

        @Test func aStaticRenderRunsNothing() {
            let log = Log()
            _ = ViewNodeToWebNodeLowerer().lowerView(
                Appearing(name: "a", log: log, container: nil).makeViewNode()
            )
            #expect(log.entries.isEmpty)
        }
    }
}
