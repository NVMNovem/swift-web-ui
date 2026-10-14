//
//  KeyedReconciliationTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 14/10/2026.
//

import Testing
@_spi(Rendering) import SwiftWebUI
@testable import SwiftWebUIRuntime

/// Keyed children are matched by identity, so reordering moves nodes instead of rewriting them.
@Suite struct KeyedReconciliationTests {
    private let differ = WebNodeDiffer()

    @Test func reorderingEmitsOneMoveAndNoContentPatches() {
        let patches = differ.diff(
            old: list(["a", "b", "c", "d"]),
            new: list(["d", "a", "b", "c"])
        )
        #expect(patches == [.moveChild(parent: NodePath(), from: 3, to: 0)])
    }

    @Test func removalComesBeforeMovesAndInsertions() {
        let patches = differ.diff(old: list(["a", "b", "c"]), new: list(["c", "x", "a"]))
        #expect(patches.first == .removeChild(parent: NodePath(), index: 1))
        #expect(patches.contains { if case .insertChild(_, 1, _) = $0 { true } else { false } })
    }

    @Test func survivingRowsAreDiffedAtTheirFinalIndex() {
        let patches = differ.diff(
            old: .fragment([row("a", "old"), row("b", "same")]),
            new: .fragment([row("b", "same"), row("a", "new")])
        )
        #expect(patches == [
            .moveChild(parent: NodePath(), from: 1, to: 0),
            // Row "a" is now child 1 and its element is the keyed fragment's child 0.
            .setText(path: NodePath([1, 0, 0]), value: "new"),
        ])
    }

    @Test func unchangedKeyedListProducesNoPatches() {
        #expect(differ.diff(old: list(["a", "b"]), new: list(["a", "b"])) == [])
    }

    @Test func unkeyedSiblingsKeepTheirPlaceWhileRowsAreInserted() {
        let header = WebNode.element(.init(tagName: "h1", children: [.text("Title")]))
        let patches = differ.diff(
            old: .fragment([header, row("a", "a")]),
            new: .fragment([header, row("b", "b"), row("a", "a")])
        )
        #expect(patches.count == 1)
        guard case .insertChild(let parent, let index, _) = patches[0] else {
            Issue.record("expected an insertion, got \(patches)")
            return
        }
        #expect(parent == NodePath())
        #expect(index == 1)
    }

    @Test func duplicateKeysFallBackToPositionalMatching() {
        let patches = differ.diff(
            old: .fragment([row("a", "1"), row("a", "2")]),
            new: .fragment([row("a", "2"), row("a", "1")])
        )
        #expect(patches.allSatisfy { if case .moveChild = $0 { false } else { true } })
        #expect(!patches.isEmpty)
    }

    @Test func aChangedKeyAtTheSameNodeReplacesIt() {
        let patches = differ.diff(old: row("a", "x"), new: row("b", "x"))
        #expect(patches.count == 1)
        guard case .replaceNode(let path, _) = patches[0] else {
            Issue.record("expected a replacement, got \(patches)")
            return
        }
        #expect(path == NodePath())
    }

    // MARK: Applying

    @Test func movedRowKeepsItsDOMNodeAndPutsItInTheRightPlace() throws {
        let backend = FakeDOMBackend()
        let old = container(["a", "b", "c"])
        let new = container(["c", "a", "b"])
        var tree = mount(old, backend: backend)
        let list = backend.root.children[0]
        let before = list.children
        backend.operations.removeAll()

        try apply(differ.diff(old: old, new: new), to: &tree, backend: backend)

        #expect(list.children.map(\.id) == [before[2].id, before[0].id, before[1].id])
        #expect(list.children[0] === before[2])
        #expect(backend.operations.allSatisfy { $0.hasPrefix("insert") })
    }

    @Test func movingToTheEndAppendsAfterTheLastSibling() throws {
        let backend = FakeDOMBackend()
        let old = container(["a", "b", "c"])
        let new = container(["b", "c", "a"])
        var tree = mount(old, backend: backend)
        let list = backend.root.children[0]
        let first = list.children[0]

        try apply(differ.diff(old: old, new: new), to: &tree, backend: backend)

        #expect(list.children.last === first)
        #expect(list.children.count == 3)
    }

    @Test func arbitraryShufflesConvergeOnTheNewOrder() throws {
        let orders: [[String]] = [
            ["a", "b", "c", "d", "e"], ["e", "d", "c", "b", "a"], ["b", "a", "d", "c", "e"],
            ["c", "x", "a"], ["x", "y", "z"], [], ["a"], ["e", "a", "y", "b", "z", "c"],
        ]
        for old in orders {
            for new in orders {
                let backend = FakeDOMBackend()
                let oldTree = container(old)
                let newTree = container(new)
                var tree = mount(oldTree, backend: backend)
                try apply(differ.diff(old: oldTree, new: newTree), to: &tree, backend: backend)
                let shown = backend.root.children[0].children.map { $0.children.first?.text ?? "" }
                #expect(shown == new, "\(old) -> \(new)")
            }
        }
    }

    @Test func rowsKeepTheirDOMNodeAcrossRealViewReordering() {
        let items = Items(["x", "y", "z"])
        let backend = FakeDOMBackend()
        let root = MountedRoot(container: backend.root, backend: backend) {
            ViewNodeToWebNodeLowerer().lowerView(ReorderableList(items: items).makeViewNode())
        }
        defer { root.stop() }
        root.start()
        let rows = backend.root.children[0].children
        let y = rows[1]

        items.value = ["z", "y", "x"]
        root.invalidate()

        let reordered = backend.root.children[0].children
        #expect(reordered.map { $0.children.first?.text ?? "" } == ["z", "y", "x"])
        #expect(reordered[1] === y)
    }

    // MARK: Helpers

    private func row(_ key: String, _ text: String) -> WebNode {
        .keyed("s:\(key)", .element(.init(tagName: "li", children: [.text(text)])))
    }

    private func list(_ keys: [String]) -> WebNode {
        .fragment(keys.map { row($0, $0) })
    }

    private func container(_ keys: [String]) -> WebNode {
        .element(.init(tagName: "ul", children: keys.map { row($0, $0) }))
    }

    private func mount(_ node: WebNode, backend: FakeDOMBackend) -> MountedNode<FakeDOMNode, Int> {
        var pending = DOMMounter<FakeDOMBackend>.PendingInsertionEffects()
        let mounter = DOMMounter(
            backend: backend,
            scrollLock: ScrollLock(backend: backend),
            transitions: TransitionScheduler(backend: backend)
        )
        let mountedNode = mounter.mount(node, pending: &pending)
        for handle in mountedNode.topLevelDOMHandles { backend.append(handle, to: backend.root) }
        mounter.flush(pending)
        return mountedNode
    }

    private func apply(
        _ patches: [DOMPatch],
        to tree: inout MountedNode<FakeDOMNode, Int>,
        backend: FakeDOMBackend
    ) throws {
        let applier = DOMPatchApplier(
            backend: backend,
            container: backend.root,
            scrollLock: ScrollLock(backend: backend),
            transitions: TransitionScheduler(backend: backend)
        )
        try applier.apply(patches, to: &tree)
    }
}

private final class Items {
    var value: [String]
    init(_ value: [String]) { self.value = value }
}

private struct ReorderableList: View {
    let items: Items

    var body: some View {
        VStack {
            ForEach(items.value, id: { $0 }) { name in
                Text(name)
            }
        }
    }
}
