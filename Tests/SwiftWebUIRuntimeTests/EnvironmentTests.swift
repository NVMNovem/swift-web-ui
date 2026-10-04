//
//  EnvironmentTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 29/09/2026.
//

import Observation
import Testing
@_spi(Runtime) @_spi(Rendering) import SwiftWebUI
@testable import SwiftWebUIRuntime

// MARK: - Fixtures

@Observable
private final class Tally {
    var count = 0
    let name: String
    init(name: String = "tally") { self.name = name }
}

/// Reads the model in `body`.
private struct TallyLabel: View {
    @Environment(Tally.self) private var tally

    var body: some View {
        Text("\(tally.name):\(tally.count)")
    }
}

/// Reads the model only inside an action, long after its body was lowered.
private struct TallyButton: View {
    @Environment(Tally.self) private var tally

    var body: some View {
        Button("+") { tally.count += 1 }
    }
}

private struct MaybeTally: View {
    @Environment(Tally.self) private var tally: Tally?

    var body: some View {
        Text(tally.map { "has \($0.name)" } ?? "none")
    }
}

private struct Screen: View {
    var body: some View {
        VStack {
            TallyLabel()
            TallyButton()
        }
    }
}

// MARK: - Helpers

private func texts(_ node: FakeDOMNode) -> [String] {
    var found: [String] = []
    if let text = node.text { found.append(text) }
    for child in node.children { found.append(contentsOf: texts(child)) }
    return found
}

private func buttons(_ node: FakeDOMNode) -> [FakeDOMNode] {
    var found: [FakeDOMNode] = []
    if node.action != nil { found.append(node) }
    for child in node.children { found.append(contentsOf: buttons(child)) }
    return found
}

private func makeRoot<Content: View>(
    _ view: @escaping () -> Content,
    backend: FakeDOMBackend
) -> MountedRoot<FakeDOMBackend> {
    MountedRoot(container: backend.root, backend: backend) {
        ViewNodeToWebNodeLowerer().lowerView(view().makeViewNode())
    }
}

// MARK: - Tests

extension RuntimeMountTests {
    @Suite struct EnvironmentTests {

        @Test func aViewReadsWhatAnAncestorPlaced() {
            let tally = Tally()
            let backend = FakeDOMBackend()
            let root = makeRoot({ Screen().environment(tally) }, backend: backend)
            defer { root.stop() }
            root.start()

            #expect(texts(backend.root) == ["tally:0", "+"])
        }

        @Test func anActionReadsItAfterTheTraversalAndTheWriteRedraws() {
            let tally = Tally()
            let backend = FakeDOMBackend()
            let root = makeRoot({ Screen().environment(tally) }, backend: backend)
            defer { root.stop() }
            root.start()

            buttons(backend.root)[0].action?()
            #expect(tally.count == 1)

            // An observed write redraws on the next turn.
            backend.runScheduledWork()
            #expect(texts(backend.root) == ["tally:1", "+"])
        }

        @Test func aNearerPlacementWinsForItsSubtreeOnly() {
            let outer = Tally(name: "outer")
            let inner = Tally(name: "inner")
            let backend = FakeDOMBackend()
            let root = makeRoot({
                VStack {
                    TallyLabel()
                    TallyLabel().environment(inner)
                    TallyLabel()
                }
                .environment(outer)
            }, backend: backend)
            defer { root.stop() }
            root.start()

            #expect(texts(backend.root) == ["outer:0", "inner:0", "outer:0"])
        }

        @Test func anOptionalReadAnswersNilWhenNothingIsPlaced() {
            let tally = Tally()
            let backend = FakeDOMBackend()
            let root = makeRoot({
                VStack {
                    MaybeTally()
                    MaybeTally().environment(tally)
                }
            }, backend: backend)
            defer { root.stop() }
            root.start()

            #expect(texts(backend.root) == ["none", "has tally"])
        }

        @Test func nothingLeaksOutOfATraversal() {
            let tally = Tally()
            let backend = FakeDOMBackend()
            let root = makeRoot({ Screen().environment(tally) }, backend: backend)
            root.start()
            root.stop()

            // A traversal restores what it found, so a later one outside the
            // placement sees nothing.
            let elsewhere = makeRoot({ MaybeTally() }, backend: backend)
            defer { elsewhere.stop() }
            elsewhere.start()
            #expect(texts(backend.root) == ["none"])
        }
    }
}
