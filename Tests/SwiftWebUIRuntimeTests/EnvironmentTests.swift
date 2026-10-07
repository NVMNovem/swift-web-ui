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

/// Reads the model only inside a key handler.
private struct TallyKeys: View {
    @Environment(Tally.self) private var tally

    var body: some View {
        Text("keys").onKeyDown("Enter") { tally.count += 10 }
    }
}

/// Reads an optional model only inside an action.
private struct MaybeTallyButton: View {
    @Environment(Tally.self) private var tally: Tally?

    var body: some View {
        Button("?") { tally?.count += 100 }
    }
}

/// Hands a closure that reads its own environment to a child placed under a nearer
/// object of the same type.
private struct OuterReader: View {
    @Environment(Tally.self) private var tally
    let inner: Tally

    var body: some View {
        VStack {
            Text(tally.name)
            Relay(name: { tally.name }).environment(inner)
        }
    }
}

private struct Relay: View {
    let name: () -> String

    var body: some View {
        Text("relayed \(name())")
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

        @Test func aKeyHandlerReadsItAfterTheTraversal() {
            let tally = Tally()
            let backend = FakeDOMBackend()
            let root = makeRoot({ TallyKeys().environment(tally) }, backend: backend)
            defer { root.stop() }
            root.start()

            func keyed(_ node: FakeDOMNode) -> FakeDOMNode? {
                if node.keyActionKeys.contains("Enter") { return node }
                return node.children.lazy.compactMap(keyed).first
            }
            keyed(backend.root)?.pressKey("Enter")
            #expect(tally.count == 10)
        }

        @Test func anActionReadsAnOptionalObjectItsBodyNeverRead() {
            let tally = Tally()
            let backend = FakeDOMBackend()
            let root = makeRoot({
                VStack {
                    MaybeTallyButton()
                    MaybeTallyButton().environment(tally)
                }
            }, backend: backend)
            defer { root.stop() }
            root.start()

            // The first button has no object and does nothing; the second finds its own.
            buttons(backend.root)[0].action?()
            #expect(tally.count == 0)
            buttons(backend.root)[1].action?()
            #expect(tally.count == 100)
        }

        @Test func anActionSeesTheObjectsOfTheViewThatWroteIt() {
            let outer = Tally(name: "outer")
            let inner = Tally(name: "inner")
            let backend = FakeDOMBackend()
            let root = makeRoot({
                VStack {
                    TallyButton()
                    TallyButton().environment(inner)
                }
                .environment(outer)
            }, backend: backend)
            defer { root.stop() }
            root.start()

            buttons(backend.root)[0].action?()
            #expect((outer.count, inner.count) == (1, 0))
            buttons(backend.root)[1].action?()
            #expect((outer.count, inner.count) == (1, 1))
        }

        @Test func aClosureCalledFurtherDownKeepsItsOwnViewsObjects() {
            let outer = Tally(name: "outer")
            let inner = Tally(name: "inner")
            let backend = FakeDOMBackend()
            let root = makeRoot({ OuterReader(inner: inner).environment(outer) }, backend: backend)
            defer { root.stop() }
            root.start()

            #expect(texts(backend.root) == ["outer", "relayed outer"])
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
