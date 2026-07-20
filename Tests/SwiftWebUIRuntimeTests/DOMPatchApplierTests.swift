import Testing
@_spi(Rendering) import SwiftWebUI
@testable import SwiftWebUIRuntime

@Suite struct DOMPatchApplierTests {
    @Test func setTextDoesNotReplaceParentOrTextNode() throws {
        let backend = FakeDOMBackend()
        var tree = mounted(element(children: [.text("0")]), backend: backend)
        let parent = backend.root.children[0]
        let text = parent.children[0]
        backend.operations.removeAll()

        try applier(backend).apply([.setText(path: NodePath([0]), value: "1")], to: &tree)

        #expect(backend.operations == ["setText \(text.id) 1"])
        #expect(backend.root.children[0] === parent)
        #expect(parent.children[0] === text)
        #expect(text.text == "1")
    }

    @Test func styleChangeCallsOnlyStyleSetter() throws {
        let backend = FakeDOMBackend()
        var tree = mounted(element(styles: [.init(name: "gap", value: "4px")]), backend: backend)
        let root = backend.root.children[0]
        backend.operations.removeAll()

        try applier(backend).apply([.setStyle(path: NodePath(), name: "gap", value: "8px")], to: &tree)

        #expect(backend.operations == ["setStyle \(root.id) gap=8px"])
        #expect(root.styles == ["gap": "8px"])
    }

    @Test func attributeChangesCallOnlyAttributeOperations() throws {
        let backend = FakeDOMBackend()
        var tree = mounted(element(attributes: [.init(name: "old", value: "x")]), backend: backend)
        let root = backend.root.children[0]
        backend.operations.removeAll()

        try applier(backend).apply([
            .removeAttribute(path: NodePath(), name: "old"),
            .setAttribute(path: NodePath(), name: "role", value: "button"),
        ], to: &tree)

        #expect(backend.operations == [
            "removeAttribute \(root.id) old",
            "setAttribute \(root.id) role=button",
        ])
        #expect(root.attributes == ["role": "button"])
    }

    @Test func appendMountsExactlyOneNewChild() throws {
        let backend = FakeDOMBackend()
        var tree = mounted(element(children: [.text("a")]), backend: backend)
        let parent = backend.root.children[0]
        backend.operations.removeAll()

        try applier(backend).apply([
            .insertChild(parent: NodePath(), index: 1, node: element("span", children: [.text("b")]))
        ], to: &tree)

        #expect(parent.children.count == 2)
        #expect(backend.operations.filter { $0.hasPrefix("createElement") }.count == 1)
        #expect(backend.operations.filter { $0.hasPrefix("insert") }.count == 1)
        guard case .element(let mountedRoot) = tree else {
            Issue.record("Expected element")
            return
        }
        #expect(mountedRoot.children.count == 2)
    }

    @Test func removeReleasesActionsAndRemovesOneChild() throws {
        let backend = FakeDOMBackend()
        var tree = mounted(element(children: [element("button", action: .closure {}), .text("tail")]), backend: backend)
        let parent = backend.root.children[0]
        let removed = parent.children[0]
        backend.operations.removeAll()

        try applier(backend).apply([.removeChild(parent: NodePath(), index: 0)], to: &tree)

        #expect(backend.releasedRegistrations == [1])
        #expect(backend.operations == ["removeAction \(removed.id) 1", "remove \(removed.id) from \(parent.id)"])
        #expect(parent.children.count == 1)
    }

    @Test func replacementRecursivelyCleansOldNode() throws {
        let backend = FakeDOMBackend()
        var tree = mounted(element(children: [
            element("section", children: [element("button", action: .closure {})])
        ]), backend: backend)
        let parent = backend.root.children[0]
        let oldSection = parent.children[0]
        let oldButton = oldSection.children[0]
        backend.operations.removeAll()

        try applier(backend).apply([
            .replaceNode(path: NodePath([0]), node: .text("replacement"))
        ], to: &tree)

        #expect(backend.releasedRegistrations == [1])
        #expect(backend.operations.contains("removeAction \(oldButton.id) 1"))
        #expect(backend.operations.contains("remove \(oldSection.id) from \(parent.id)"))
        #expect(parent.children.count == 1)
        #expect(parent.children[0].text == "replacement")
    }

    @Test func mountedMetadataStaysSynchronized() throws {
        let backend = FakeDOMBackend()
        var tree = mounted(element(
            attributes: [.init(name: "old", value: "x")],
            styles: [.init(name: "gap", value: "4px")],
            children: [.text("0")]
        ), backend: backend)

        try applier(backend).apply([
            .removeAttribute(path: NodePath(), name: "old"),
            .setAttribute(path: NodePath(), name: "role", value: "status"),
            .setStyle(path: NodePath(), name: "gap", value: "8px"),
            .setText(path: NodePath([0]), value: "1"),
        ], to: &tree)

        guard case .element(let root) = tree,
              case .text(let text) = root.children[0] else {
            Issue.record("Expected mounted element and text")
            return
        }
        #expect(root.attributes == [.init(name: "role", value: "status")])
        #expect(root.styles == [.init(name: "gap", value: "8px")])
        #expect(text.value == "1")
    }

    @Test func multipleSequentialUpdatesRemainCorrect() throws {
        let backend = FakeDOMBackend()
        let differ = WebNodeDiffer()
        var old = element(children: [.text("0")])
        var tree = mounted(old, backend: backend)
        let parent = backend.root.children[0]
        let text = parent.children[0]

        for value in 1...3 {
            let new = element(children: [.text(String(value))])
            try applier(backend).apply(differ.diff(old: old, new: new), to: &tree)
            old = new
        }

        #expect(text.text == "3")
        #expect(parent.children[0] === text)
        #expect(backend.root.children[0] === parent)
    }

    @Test func pathsRemainValidAfterTrailingInsertAndRemove() throws {
        let backend = FakeDOMBackend()
        var tree = mounted(element(children: [.text("a")]), backend: backend)
        let patcher = applier(backend)

        try patcher.apply([.insertChild(parent: NodePath(), index: 1, node: .text("b"))], to: &tree)
        try patcher.apply([.setText(path: NodePath([1]), value: "B")], to: &tree)
        try patcher.apply([.removeChild(parent: NodePath(), index: 1)], to: &tree)
        try patcher.apply([.setText(path: NodePath([0]), value: "A")], to: &tree)

        let parent = backend.root.children[0]
        #expect(parent.children.count == 1)
        #expect(parent.children[0].text == "A")
    }

    private func applier(_ backend: FakeDOMBackend) -> DOMPatchApplier<FakeDOMBackend> {
        DOMPatchApplier(backend: backend, container: backend.root)
    }
}
