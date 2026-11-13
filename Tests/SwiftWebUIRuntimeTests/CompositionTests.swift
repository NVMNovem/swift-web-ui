//
//  CompositionTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 13/11/2026.
//

import Testing
@_spi(Runtime) @_spi(Rendering) import SwiftWebUI
@testable import SwiftWebUIRuntime

// MARK: - Fixtures

private struct Card: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.px(16))
            .background(.white)
            .cornerRadius(.px(12))
    }
}

private struct Tagged: ViewModifier {
    let tag: String

    func body(content: Content) -> some View {
        VStack {
            Text(tag)
            content
        }
    }
}

/// A modifier with state of its own, toggled by a button it adds.
private struct Expanding: ViewModifier {
    @State private var expanded = false

    func body(content: Content) -> some View {
        VStack {
            Button(expanded ? "less" : "more") { expanded.toggle() }
            if expanded {
                content
            }
        }
    }
}

private struct Counter: View {
    @State private var count = 0

    var body: some View {
        Button("count " + String(count)) { count += 1 }
    }
}

private struct GreetingKey: EnvironmentKey {
    static let defaultValue = "hello"
}

private struct Greeting: View {
    @Environment(GreetingKey.self) private var greeting

    var body: some View {
        Text(greeting)
    }
}

/// Places a value around its content, as a theme modifier would.
private struct Greets: ViewModifier {
    let greeting: String

    func body(content: Content) -> some View {
        content.environment(GreetingKey.self, greeting)
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
    _ view: Content,
    backend: FakeDOMBackend
) -> MountedRoot<FakeDOMBackend> {
    MountedRoot(container: backend.root, backend: backend) {
        ViewNodeToWebNodeLowerer().lowerView(view.makeViewNode())
    }
}

/// What mounting `view` does to a fresh document, operation by operation.
private func mountOperations<Content: View>(_ view: Content) -> [String] {
    let backend = FakeDOMBackend()
    let root = makeRoot(view, backend: backend)
    root.start()
    defer { root.stop() }
    return backend.operations
}

// MARK: - Tests

extension RuntimeMountTests {
    @Suite struct CompositionTests {

        @Test func aModifierLowersExactlyAsItsBodyWritten() {
            let viaModifier = mountOperations(Text("Fries").modifier(Card()))
            let written = mountOperations(
                Text("Fries")
                    .padding(.px(16))
                    .background(.white)
                    .cornerRadius(.px(12))
            )
            #expect(viaModifier == written)
        }

        @Test func aModifierPlacesTheContentWhereItsBodySays() {
            let backend = FakeDOMBackend()
            let root = makeRoot(Text("Fries").modifier(Tagged(tag: "New")), backend: backend)
            defer { root.stop() }

            root.start()
            #expect(texts(backend.root) == ["New", "Fries"])
        }

        @Test func aModifierKeepsItsOwnStateAndTheContentKeepsItsOwn() {
            let backend = FakeDOMBackend()
            let root = makeRoot(Counter().modifier(Expanding()), backend: backend)
            defer { root.stop() }

            root.start()
            #expect(texts(backend.root) == ["more"])

            buttons(backend.root)[0].action?()
            backend.runScheduledWork()
            #expect(texts(backend.root) == ["less", "count 0"])

            buttons(backend.root)[1].action?()
            backend.runScheduledWork()
            #expect(texts(backend.root) == ["less", "count 1"])
        }

        @Test func anEnvironmentValueReachesTheSubtree() {
            let backend = FakeDOMBackend()
            let root = makeRoot(
                VStack {
                    Greeting()
                    Greeting().environment(GreetingKey.self, "hoi")
                },
                backend: backend
            )
            defer { root.stop() }

            root.start()
            #expect(texts(backend.root) == ["hello", "hoi"])
        }

        @Test func aNearerPlacementReplacesAnOuterOneForItsSubtreeOnly() {
            let backend = FakeDOMBackend()
            let root = makeRoot(
                VStack {
                    Greeting()
                    Greeting().environment(GreetingKey.self, "bonjour")
                }
                .environment(GreetingKey.self, "hoi"),
                backend: backend
            )
            defer { root.stop() }

            root.start()
            #expect(texts(backend.root) == ["hoi", "bonjour"])
        }

        @Test func aModifierCanPlaceAValueAroundItsContent() {
            let backend = FakeDOMBackend()
            let root = makeRoot(Greeting().modifier(Greets(greeting: "salut")), backend: backend)
            defer { root.stop() }

            root.start()
            #expect(texts(backend.root) == ["salut"])
        }
    }
}
