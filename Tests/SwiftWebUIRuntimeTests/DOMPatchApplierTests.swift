//
//  DOMPatchApplierTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

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

    @Test func unitlessLineHeightMountsAndReconcilesWithoutAppendingPixels() throws {
        let backend = FakeDOMBackend()
        let differ = WebNodeDiffer()
        let lowerer = ViewNodeToWebNodeLowerer()
        let old = lowerer.lower(Text("Paragraph").lineHeight(.normal).makeViewNode())
        let new = lowerer.lower(Text("Paragraph").lineHeight(.multiple(1.7)).makeViewNode())
        var tree = mounted(old, backend: backend)
        let root = backend.root.children[0]
        backend.operations.removeAll()

        try applier(backend).apply(differ.diff(old: old, new: new), to: &tree)

        #expect(backend.operations == ["setStyle \(root.id) line-height=1.7"])
        #expect(root.styles["line-height"] == "1.7")
        #expect(root.styles["line-height"] != "1.7px")
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

    @Test func mountingFocusesOnlyAfterTheHandleIsInTheDocument() {
        let backend = FakeDOMBackend()
        _ = mounted(element("input", requestsFocus: true), backend: backend)
        let input = backend.root.children[0]

        // `focus()` on a detached node is silently a no-op, so the focus call
        // must come after the append that puts the handle in the document.
        let appendIndex = backend.operations.firstIndex(of: "append \(input.id) to \(backend.root.id)")
        let focusIndex = backend.operations.firstIndex(of: "focus \(input.id)")
        #expect(appendIndex != nil)
        #expect(focusIndex != nil)
        if let appendIndex, let focusIndex { #expect(appendIndex < focusIndex) }
        #expect(backend.focusedNodes.count == 1)
    }

    @Test func focusPatchFocusesTheElementAtItsPath() throws {
        let backend = FakeDOMBackend()
        var tree = mounted(element(children: [element("input"), element("input")]), backend: backend)
        let second = backend.root.children[0].children[1]
        backend.operations.removeAll()

        try applier(backend).apply([.focus(path: NodePath([1]))], to: &tree)

        #expect(backend.operations == ["focus \(second.id)"])
        #expect(backend.focusedNodes.last === second)
    }

    @Test func aChildInsertedAskingForFocusIsFocusedAfterItIsInserted() throws {
        let backend = FakeDOMBackend()
        var tree = mounted(element(children: [element("input")]), backend: backend)
        let parent = backend.root.children[0]
        backend.operations.removeAll()

        try applier(backend).apply(
            [.insertChild(parent: NodePath(), index: 1, node: element("input", requestsFocus: true))],
            to: &tree
        )

        let inserted = parent.children[1]
        let insertIndex = backend.operations.firstIndex { $0.hasPrefix("insert \(inserted.id) into") }
        let focusIndex = backend.operations.firstIndex(of: "focus \(inserted.id)")
        #expect(insertIndex != nil)
        #expect(focusIndex != nil)
        if let insertIndex, let focusIndex { #expect(insertIndex < focusIndex) }
    }

    @Test func mountedKeyHandlerFiresOnlyForItsOwnKey() {
        let backend = FakeDOMBackend()
        var escapes = 0
        var enters = 0
        _ = mounted(
            element(keyActions: [
                .init(key: "Escape", action: .closure { escapes += 1 }),
                .init(key: "Enter", action: .closure { enters += 1 }),
            ]),
            backend: backend
        )
        let node = backend.root.children[0]

        node.pressKey("Escape")
        node.pressKey("ArrowDown")
        node.pressKey("Enter")

        #expect(escapes == 1)
        #expect(enters == 1)
    }

    @Test func replacingKeyActionsReleasesTheOldRegistrationFirst() throws {
        let backend = FakeDOMBackend()
        var tree = mounted(
            element(keyActions: [.init(key: "Escape", action: .closure {})]),
            backend: backend
        )
        let node = backend.root.children[0]
        backend.operations.removeAll()
        backend.releasedRegistrations.removeAll()

        var fired = 0
        try applier(backend).apply(
            [.replaceKeyActions(path: NodePath(), actions: [.init(key: "Enter", action: .closure { fired += 1 })])],
            to: &tree
        )

        #expect(backend.releasedRegistrations.count == 1)
        #expect(backend.operations.contains { $0.hasPrefix("removeKeyAction \(node.id)") })
        #expect(backend.operations.contains { $0.hasPrefix("setKeyAction \(node.id)") })

        node.pressKey("Escape")
        #expect(fired == 0)
        node.pressKey("Enter")
        #expect(fired == 1)
    }

    @Test func removingASubtreeReleasesItsKeyRegistrations() throws {
        let backend = FakeDOMBackend()
        var tree = mounted(
            element(children: [
                element("div", keyActions: [.init(key: "Escape", action: .closure {})]),
            ]),
            backend: backend
        )
        backend.releasedRegistrations.removeAll()

        try applier(backend).apply([.removeChild(parent: NodePath(), index: 0)], to: &tree)

        // An unreleased handler leaks on every rebuild.
        #expect(backend.releasedRegistrations.count == 1)
    }

    @Test func mountingAndUnmountingRepeatedlyLeaksNoKeyRegistrations() throws {
        let backend = FakeDOMBackend()
        var tree = mounted(element(), backend: backend)
        let applier = applier(backend)

        for _ in 0..<100 {
            try applier.apply(
                [.insertChild(
                    parent: NodePath(),
                    index: 0,
                    node: element("div", keyActions: [.init(key: "Escape", action: .closure {})])
                )],
                to: &tree
            )
            try applier.apply([.removeChild(parent: NodePath(), index: 0)], to: &tree)
        }

        #expect(backend.releasedRegistrations.count == 100)
        #expect(backend.root.children[0].children.isEmpty)
    }

    @Test func aPresentedModalDialogIsShownOnlyAfterItIsInTheDocument() {
        let backend = FakeDOMBackend()
        _ = mounted(element("dialog", presentation: .modal), backend: backend)
        let dialog = backend.root.children[0]

        // `showModal()` on a detached node throws, so it has to follow the append.
        let appendIndex = backend.operations.firstIndex(of: "append \(dialog.id) to \(backend.root.id)")
        let presentIndex = backend.operations.firstIndex(of: "presentDialog \(dialog.id) modal=true")
        #expect(appendIndex != nil)
        #expect(presentIndex != nil)
        if let appendIndex, let presentIndex { #expect(appendIndex < presentIndex) }
        #expect(dialog.isPresented)
        #expect(dialog.isModal)
    }

    @Test func aDismissedDialogIsNeverShownOnMount() {
        let backend = FakeDOMBackend()
        _ = mounted(element("dialog", presentation: .dismissed), backend: backend)

        #expect(!backend.root.children[0].isPresented)
        #expect(!backend.operations.contains { $0.hasPrefix("presentDialog") })
    }

    @Test func presentingAModalDialogTakesTheScrollLockAndDismissingGivesItBack() throws {
        let backend = FakeDOMBackend()
        let scrollLock = ScrollLock(backend: backend)
        var tree = mounted(
            element("dialog", presentation: .dismissed),
            backend: backend,
            scrollLock: scrollLock
        )
        #expect(!scrollLock.isLocked)

        try applier(backend, scrollLock: scrollLock).apply(
            [.setDialogPresentation(path: NodePath(), presentation: .modal)],
            to: &tree
        )
        #expect(scrollLock.isLocked)
        #expect(backend.body.styles["overflow"] == "hidden")

        try applier(backend, scrollLock: scrollLock).apply(
            [.setDialogPresentation(path: NodePath(), presentation: .dismissed)],
            to: &tree
        )
        #expect(!scrollLock.isLocked)
        #expect(backend.body.styles["overflow"] == nil)
    }

    @Test func presentingTheSameDialogTwiceTakesTheScrollLockOnce() throws {
        let backend = FakeDOMBackend()
        let scrollLock = ScrollLock(backend: backend)
        var tree = mounted(
            element("dialog", presentation: .modal),
            backend: backend,
            scrollLock: scrollLock
        )
        let applier = applier(backend, scrollLock: scrollLock)

        try applier.apply([.setDialogPresentation(path: NodePath(), presentation: .modal)], to: &tree)
        try applier.apply([.setDialogPresentation(path: NodePath(), presentation: .dismissed)], to: &tree)

        // An element that took the lock once must give it back exactly once.
        #expect(!scrollLock.isLocked)
        #expect(backend.body.styles["overflow"] == nil)
    }

    @Test func twoNestedSheetsRestoreScrollingExactlyOnce() throws {
        let backend = FakeDOMBackend()
        let scrollLock = ScrollLock(backend: backend)
        var tree = mounted(
            element(children: [
                element("dialog", presentation: .modal),
                element("dialog", presentation: .modal),
            ]),
            backend: backend,
            scrollLock: scrollLock
        )
        let applier = applier(backend, scrollLock: scrollLock)
        #expect(scrollLock.isLocked)

        try applier.apply([.setDialogPresentation(path: NodePath([1]), presentation: .dismissed)], to: &tree)
        #expect(scrollLock.isLocked)

        try applier.apply([.setDialogPresentation(path: NodePath([0]), presentation: .dismissed)], to: &tree)
        #expect(!scrollLock.isLocked)
        #expect(backend.body.styles["overflow"] == nil)
    }

    @Test func removingAPresentedDialogGivesTheScrollLockBack() throws {
        let backend = FakeDOMBackend()
        let scrollLock = ScrollLock(backend: backend)
        var tree = mounted(
            element(children: [element("dialog", presentation: .modal)]),
            backend: backend,
            scrollLock: scrollLock
        )
        #expect(scrollLock.isLocked)

        try applier(backend, scrollLock: scrollLock)
            .apply([.removeChild(parent: NodePath(), index: 0)], to: &tree)

        // Otherwise the page could never scroll again.
        #expect(!scrollLock.isLocked)
        #expect(backend.body.styles["overflow"] == nil)
    }

    @Test func theBrowserClosingADialogRunsItsDismissAction() {
        let backend = FakeDOMBackend()
        var dismissed = 0
        _ = mounted(
            element("dialog", presentation: .modal, dismissAction: .closure { dismissed += 1 }),
            backend: backend
        )
        let dialog = backend.root.children[0]

        // Escape and the backdrop end in the same place: the browser closes the
        // dialog without asking, and the binding has to hear about it.
        dialog.browserDismiss()

        #expect(dismissed == 1)
        #expect(!dialog.isPresented)
    }

    @Test func removingADialogReleasesItsDismissRegistration() throws {
        let backend = FakeDOMBackend()
        var tree = mounted(
            element(children: [element("dialog", presentation: .dismissed, dismissAction: .closure {})]),
            backend: backend
        )
        backend.releasedRegistrations.removeAll()

        try applier(backend).apply([.removeChild(parent: NodePath(), index: 0)], to: &tree)

        #expect(backend.releasedRegistrations.count == 1)
    }

    private func applier(
        _ backend: FakeDOMBackend,
        scrollLock: ScrollLock<FakeDOMBackend>? = nil,
        transitions: TransitionScheduler<FakeDOMBackend>? = nil
    ) -> DOMPatchApplier<FakeDOMBackend> {
        DOMPatchApplier(
            backend: backend,
            container: backend.root,
            scrollLock: scrollLock ?? ScrollLock(backend: backend),
            transitions: transitions ?? TransitionScheduler(backend: backend)
        )
    }
}
