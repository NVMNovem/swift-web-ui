//
//  StateSlotTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 07/08/2026.
//

import Testing
@_spi(Runtime) @_spi(Rendering) import SwiftWebUI
@testable import SwiftWebUIRuntime

// MARK: - Fixtures

private final class Flag {
    var value: Bool
    init(_ value: Bool) { self.value = value }
}

private final class Box<T> {
    var value: T
    init(_ value: T) { self.value = value }
}

private struct Counter: View {
    let label: String
    @State private var count = 0

    var body: some View {
        VStack {
            Text(label + ":" + String(count))
            Button("+") { count += 1 }
        }
    }
}

private struct TwoCounters: View {
    var body: some View {
        VStack {
            Counter(label: "a")
            Counter(label: "b")
        }
    }
}

private struct BranchRoot: View {
    let flag: Flag

    var body: some View {
        VStack {
            if flag.value {
                Counter(label: "t")
            } else {
                Counter(label: "f")
            }
        }
    }
}

private struct KeyedList: View {
    let items: Box<[String]>

    var body: some View {
        VStack {
            ForEach(items.value, id: { $0 }) { name in
                Counter(label: name)
            }
        }
    }
}

private struct Row: Identifiable {
    let id: String
}

private struct IdentifiableList: View {
    let items: Box<[Row]>

    var body: some View {
        VStack {
            ForEach(items.value) { row in
                Counter(label: row.id)
            }
        }
    }
}

private struct UnkeyedList: View {
    let items: Box<[String]>

    var body: some View {
        VStack {
            ForEach(items.value) { name in
                Counter(label: name)
            }
        }
    }
}

/// Reads its state only while expanded, to exercise liveness-based sweeping.
private struct Expandable: View {
    let expanded: Flag
    @State private var count = 0

    var body: some View {
        VStack {
            Button("+") { count += 1 }
            if expanded.value {
                Text("n=" + String(count))
            } else {
                Text("collapsed")
            }
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
    _ view: Content,
    backend: FakeDOMBackend
) -> MountedRoot<FakeDOMBackend> {
    MountedRoot(container: backend.root, backend: backend) {
        ViewNodeToWebNodeLowerer().lower(view.makeViewNode())
    }
}

// MARK: - Tests

extension RuntimeMountTests {
    @Suite struct StateSlotTests {
        /// The regression this whole feature exists for: before state slots, a subview was
        /// reconstructed on every rebuild and its `@State` snapped back to the initial value.
        @Test func subviewStateSurvivesRebuild() {
            let backend = FakeDOMBackend()
            let root = makeRoot(Counter(label: "a"), backend: backend)
            defer { root.stop() }
            root.start()

            #expect(texts(backend.root) == ["a:0", "+"])
            buttons(backend.root)[0].action?()
            #expect(texts(backend.root) == ["a:1", "+"])
            buttons(backend.root)[0].action?()
            buttons(backend.root)[0].action?()
            #expect(texts(backend.root) == ["a:3", "+"])
        }

        /// Subview state must not cost DOM identity: the rebuild patches the text in place
        /// rather than remounting the subtree.
        @Test func subviewStateChangePatchesTextInPlace() {
            let backend = FakeDOMBackend()
            let root = makeRoot(Counter(label: "a"), backend: backend)
            defer { root.stop() }
            root.start()

            let button = buttons(backend.root)[0]
            let label = texts(backend.root)
            #expect(label == ["a:0", "+"])

            var textNode: FakeDOMNode?
            func findText(_ node: FakeDOMNode) {
                if node.text == "a:0" { textNode = node }
                for child in node.children { findText(child) }
            }
            findText(backend.root)
            let originalText = try! #require(textNode)

            backend.operations.removeAll()
            button.action?()

            #expect(backend.operations.contains("setText \(originalText.id) a:1"))
            #expect(!backend.operations.contains { $0.hasPrefix("createElement") })
            #expect(originalText.text == "a:1")
        }

        @Test func siblingSubviewsKeepIndependentState() {
            let backend = FakeDOMBackend()
            let root = makeRoot(TwoCounters(), backend: backend)
            defer { root.stop() }
            root.start()

            #expect(texts(backend.root) == ["a:0", "+", "b:0", "+"])
            buttons(backend.root)[0].action?()
            buttons(backend.root)[0].action?()
            #expect(texts(backend.root) == ["a:2", "+", "b:0", "+"])
            buttons(backend.root)[1].action?()
            #expect(texts(backend.root) == ["a:2", "+", "b:1", "+"])
        }

        /// A view that moves to the other side of an `if` is a different view, so it starts
        /// over -- the same reset SwiftUI performs.
        @Test func flippingConditionalBranchResetsState() {
            let flag = Flag(false)
            let backend = FakeDOMBackend()
            let root = makeRoot(BranchRoot(flag: flag), backend: backend)
            defer { root.stop() }
            root.start()

            buttons(backend.root)[0].action?()
            buttons(backend.root)[0].action?()
            #expect(texts(backend.root) == ["f:2", "+"])

            flag.value = true
            root.invalidate()
            #expect(texts(backend.root) == ["t:0", "+"])

            flag.value = false
            root.invalidate()
            #expect(texts(backend.root) == ["f:0", "+"])
        }

        @Test func keyedForEachRowStateFollowsItsElement() {
            let items = Box(["x", "y", "z"])
            let backend = FakeDOMBackend()
            let root = makeRoot(KeyedList(items: items), backend: backend)
            defer { root.stop() }
            root.start()

            #expect(texts(backend.root) == ["x:0", "+", "y:0", "+", "z:0", "+"])
            buttons(backend.root)[1].action?()
            buttons(backend.root)[1].action?()
            #expect(texts(backend.root) == ["x:0", "+", "y:2", "+", "z:0", "+"])

            items.value = ["y", "z"]
            root.invalidate()
            #expect(texts(backend.root) == ["y:2", "+", "z:0", "+"])
        }

        /// `Identifiable` elements are keyed without writing `id:` at the call site.
        @Test func identifiableForEachIsKeyedAutomatically() {
            let items = Box([Row(id: "x"), Row(id: "y")])
            let backend = FakeDOMBackend()
            let root = makeRoot(IdentifiableList(items: items), backend: backend)
            defer { root.stop() }
            root.start()

            buttons(backend.root)[1].action?()
            #expect(texts(backend.root) == ["x:0", "+", "y:1", "+"])

            items.value = [Row(id: "y")]
            root.invalidate()
            #expect(texts(backend.root) == ["y:1", "+"])
        }

        /// Documents why `id:` matters: without it, rows are positional and state slides.
        @Test func unkeyedForEachRowStateIsPositional() {
            let items = Box(["x", "y", "z"])
            let backend = FakeDOMBackend()
            let root = makeRoot(UnkeyedList(items: items), backend: backend)
            defer { root.stop() }
            root.start()

            buttons(backend.root)[1].action?()
            buttons(backend.root)[1].action?()
            #expect(texts(backend.root) == ["x:0", "+", "y:2", "+", "z:0", "+"])

            items.value = ["y", "z"]
            root.invalidate()
            // "y" moved into slot 0 and inherited the state that belonged to "x".
            #expect(texts(backend.root) == ["y:0", "+", "z:2", "+"])
        }

        /// Slots are reclaimed by view liveness, not by whether a state was read. A state
        /// read on only one branch must survive while its view stays mounted.
        @Test func stateReadOnOneBranchSurvivesCollapse() {
            let expanded = Flag(true)
            let backend = FakeDOMBackend()
            let root = makeRoot(Expandable(expanded: expanded), backend: backend)
            defer { root.stop() }
            root.start()

            buttons(backend.root)[0].action?()
            buttons(backend.root)[0].action?()
            #expect(texts(backend.root) == ["+", "n=2"])

            expanded.value = false
            root.invalidate()
            #expect(texts(backend.root) == ["+", "collapsed"])

            expanded.value = true
            root.invalidate()
            #expect(texts(backend.root) == ["+", "n=2"])
        }

        @Test func vanishedSubviewReleasesItsSlot() {
            let items = Box(["x", "y", "z"])
            let backend = FakeDOMBackend()
            let root = makeRoot(KeyedList(items: items), backend: backend)
            defer { root.stop() }
            root.start()

            #expect(root.stateSlots.slotCount == 3)

            items.value = ["y"]
            root.invalidate()
            #expect(root.stateSlots.slotCount == 1)

            items.value = []
            root.invalidate()
            #expect(root.stateSlots.slotCount == 0)
        }

        /// Static rendering installs no store, so `State` falls back to per-instance storage
        /// and lowering stays a pure function.
        @Test func loweringWithoutAStoreUsesFallbackStorage() {
            let node = Counter(label: "a").makeViewNode()
            let web = ViewNodeToWebNodeLowerer().lower(node)
            let backend = FakeDOMBackend()
            _ = mounted(web, backend: backend)
            #expect(texts(backend.root) == ["a:0", "+"])
        }
    }
}
