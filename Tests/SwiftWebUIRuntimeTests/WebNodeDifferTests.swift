//
//  WebNodeDifferTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

import Testing
@_spi(Rendering) import SwiftWebUI
@testable import SwiftWebUIRuntime

@Suite struct WebNodeDifferTests {
    private let differ = WebNodeDiffer()

    @Test func identicalTreesProduceNoPatches() {
        let tree = element(attributes: [.init(name: "id", value: "a")], children: [.text("same")])
        #expect(differ.diff(old: tree, new: tree) == [])
    }

    @Test func changedTextProducesExactlySetText() {
        #expect(differ.diff(old: .text("0"), new: .text("1")) == [
            .setText(path: NodePath(), value: "1")
        ])
    }

    @Test func unchangedTextProducesNoPatches() {
        #expect(differ.diff(old: .text("same"), new: .text("same")) == [])
    }

    @Test(arguments: [
        ([], [WebAttribute(name: "role", value: "button")], [DOMPatch.setAttribute(path: NodePath(), name: "role", value: "button")]),
        ([WebAttribute(name: "role", value: "link")], [WebAttribute(name: "role", value: "button")], [DOMPatch.setAttribute(path: NodePath(), name: "role", value: "button")]),
        ([WebAttribute(name: "role", value: "button")], [], [DOMPatch.removeAttribute(path: NodePath(), name: "role")]),
    ])
    func attributeChanges(old: [WebAttribute], new: [WebAttribute], expected: [DOMPatch]) {
        #expect(differ.diff(old: element(attributes: old), new: element(attributes: new)) == expected)
    }

    @Test(arguments: [
        ([], [WebStyleDeclaration(name: "gap", value: "8px")], [DOMPatch.setStyle(path: NodePath(), name: "gap", value: "8px")]),
        ([WebStyleDeclaration(name: "gap", value: "4px")], [WebStyleDeclaration(name: "gap", value: "8px")], [DOMPatch.setStyle(path: NodePath(), name: "gap", value: "8px")]),
        ([WebStyleDeclaration(name: "gap", value: "8px")], [], [DOMPatch.removeStyle(path: NodePath(), name: "gap")]),
    ])
    func styleChanges(old: [WebStyleDeclaration], new: [WebStyleDeclaration], expected: [DOMPatch]) {
        #expect(differ.diff(old: element(styles: old), new: element(styles: new)) == expected)
    }

    /// `.buttonStyle(.primary).background(...)` declares `background-color` twice; the element
    /// normalizes to the last declaration, so a rerender must not revive the first one.
    @Test func redeclaredStylesAndAttributesProduceNoPatches() {
        let tree = element(
            attributes: [.init(name: "role", value: "link"), .init(name: "role", value: "button")],
            styles: [
                .init(name: "background-color", value: "#000"),
                .init(name: "font-weight", value: "600"),
                .init(name: "background-color", value: "var(--accent)"),
            ]
        )
        #expect(differ.diff(old: tree, new: tree) == [])
    }

    /// Only the surviving declaration participates in the diff, from either side.
    @Test func redeclaredStylePatchesOnlyTheSurvivingDeclaration() {
        let old = element(styles: [
            .init(name: "background-color", value: "#000"),
            .init(name: "background-color", value: "var(--accent)"),
        ])
        #expect(differ.diff(
            old: old,
            new: element(styles: [.init(name: "background-color", value: "#fff")])
        ) == [.setStyle(path: NodePath(), name: "background-color", value: "#fff")])
        #expect(differ.diff(old: old, new: element()) == [
            .removeStyle(path: NodePath(), name: "background-color")
        ])
    }

    @Test func tagChangeReplacesNode() {
        let replacement = element("button")
        #expect(differ.diff(old: element("div"), new: replacement) == [
            .replaceNode(path: NodePath(), node: replacement)
        ])
    }

    @Test func nodeKindChangeReplacesNode() {
        #expect(differ.diff(old: .empty, new: .text("value")) == [
            .replaceNode(path: NodePath(), node: .text("value"))
        ])
    }

    @Test func appendTrailingChild() {
        #expect(differ.diff(
            old: element(children: [.text("a")]),
            new: element(children: [.text("a"), .text("b")])
        ) == [.insertChild(parent: NodePath(), index: 1, node: .text("b"))])
    }

    @Test func removeTrailingChildrenUsesDescendingIndices() {
        #expect(differ.diff(
            old: element(children: [.text("a"), .text("b"), .text("c")]),
            new: element(children: [.text("a")])
        ) == [
            .removeChild(parent: NodePath(), index: 2),
            .removeChild(parent: NodePath(), index: 1),
        ])
    }

    @Test func nestedTextChangeUsesMountedTreePath() {
        #expect(differ.diff(
            old: element(children: [element("span", children: [.text("0")])]),
            new: element(children: [element("span", children: [.text("1")])])
        ) == [.setText(path: NodePath([0, 0]), value: "1")])
    }

    @Test func fragmentChangesUsePositionalChildren() {
        #expect(differ.diff(
            old: .fragment([.text("0"), .text("tail")]),
            new: .fragment([.text("1"), .text("tail"), .empty])
        ) == [
            .setText(path: NodePath([0]), value: "1"),
            .insertChild(parent: NodePath(), index: 2, node: .empty),
        ])
    }

    @Test func patchOrderIsDeterministic() {
        let old = element(
            attributes: [.init(name: "removed", value: "x"), .init(name: "changed", value: "a")],
            styles: [.init(name: "old", value: "x"), .init(name: "gap", value: "4px")],
            children: [.text("0"), .text("remove")]
        )
        let new = element(
            attributes: [.init(name: "changed", value: "b"), .init(name: "added", value: "y")],
            styles: [.init(name: "gap", value: "8px"), .init(name: "new", value: "y")],
            children: [.text("1")]
        )
        #expect(differ.diff(old: old, new: new) == [
            .removeAttribute(path: NodePath(), name: "removed"),
            .setAttribute(path: NodePath(), name: "changed", value: "b"),
            .setAttribute(path: NodePath(), name: "added", value: "y"),
            .removeStyle(path: NodePath(), name: "old"),
            .setStyle(path: NodePath(), name: "gap", value: "8px"),
            .setStyle(path: NodePath(), name: "new", value: "y"),
            .setText(path: NodePath([0]), value: "1"),
            .removeChild(parent: NodePath(), index: 1),
        ])
    }

    @Test func closureActionIsConservativelyReplaced() {
        let old = element("button", action: .closure {})
        let newAction = ActionIntent.closure {}
        #expect(differ.diff(old: old, new: element("button", action: newAction)) == [
            .replaceAction(path: NodePath(), action: newAction)
        ])
    }

    @Test func askingForFocusForTheFirstTimeEmitsExactlyOneFocusPatch() {
        #expect(differ.diff(
            old: element(requestsFocus: false),
            new: element(requestsFocus: true)
        ) == [.focus(path: NodePath())])
    }

    @Test func alreadyFocusedElementDoesNotReclaimFocusOnUnrelatedChanges() {
        // Re-emitting focus on every rerender would yank it back mid-typing.
        let patches = differ.diff(
            old: element(styles: [.init(name: "gap", value: "4px")], requestsFocus: true),
            new: element(styles: [.init(name: "gap", value: "8px")], requestsFocus: true)
        )
        #expect(patches == [.setStyle(path: NodePath(), name: "gap", value: "8px")])
    }

    @Test func droppingTheFocusRequestEmitsNothing() {
        #expect(differ.diff(
            old: element(requestsFocus: true),
            new: element(requestsFocus: false)
        ) == [])
    }

    @Test func focusIsRequestedAtTheElementThatAskedForIt() {
        let old = element(children: [element("input"), element("input")])
        let new = element(children: [element("input"), element("input", requestsFocus: true)])
        #expect(differ.diff(old: old, new: new) == [.focus(path: NodePath([1]))])
    }


    @Test func addingAKeyHandlerReplacesTheElementsKeyRegistrations() {
        let patches = differ.diff(
            old: element(),
            new: element(keyActions: [.init(key: "Escape", action: .closure {})])
        )
        #expect(patches == [.replaceKeyActions(path: NodePath(), actions: [.init(key: "Escape", action: .closure {})])])
    }

    @Test func aRerenderCarryingTheSameKeyClosureStillReplacesConservatively() {
        // Closures have no renderer-neutral identity, so "same key, some
        // closure" cannot be shown to be the same closure.
        let patches = differ.diff(
            old: element(keyActions: [.init(key: "Escape", action: .closure {})]),
            new: element(keyActions: [.init(key: "Escape", action: .closure {})])
        )
        #expect(patches.count == 1)
        #expect(patches.first == .replaceKeyActions(path: NodePath(), actions: [.init(key: "Escape", action: .closure {})]))
    }

    @Test func anElementWithNoKeyHandlersEitherSideProducesNoKeyPatch() {
        #expect(differ.diff(old: element(), new: element()) == [])
    }

    @Test func droppingTheLastKeyHandlerEmptiesTheRegistrations() {
        let patches = differ.diff(
            old: element(keyActions: [.init(key: "Escape", action: .closure {})]),
            new: element()
        )
        #expect(patches == [.replaceKeyActions(path: NodePath(), actions: [])])
    }


    @Test func presentingADialogEmitsAPresentationPatch() {
        #expect(differ.diff(
            old: element("dialog", presentation: .dismissed),
            new: element("dialog", presentation: .modal)
        ) == [.setDialogPresentation(path: NodePath(), presentation: .modal)])
    }

    @Test func dismissingADialogEmitsAPresentationPatch() {
        #expect(differ.diff(
            old: element("dialog", presentation: .modal),
            new: element("dialog", presentation: .dismissed)
        ) == [.setDialogPresentation(path: NodePath(), presentation: .dismissed)])
    }

    @Test func anUnchangedPresentationEmitsNothing() {
        #expect(differ.diff(
            old: element("dialog", presentation: .modal),
            new: element("dialog", presentation: .modal)
        ) == [])
    }

    @Test func changingModalityIsAPresentationChange() {
        #expect(differ.diff(
            old: element("dialog", presentation: .nonModal),
            new: element("dialog", presentation: .modal)
        ) == [.setDialogPresentation(path: NodePath(), presentation: .modal)])
    }


    @Test func changingTransitionPhasesKeepsTheMountedTreeAccurate() {
        let phases = TransitionPhases(enter: "in", exit: "out", durationMilliseconds: 200)
        #expect(differ.diff(
            old: element(),
            new: element(transitionPhases: phases)
        ) == [.setTransitionPhases(path: NodePath(), phases: phases)])
    }

    @Test func unchangedTransitionPhasesEmitNothing() {
        let phases = TransitionPhases(enter: "in", exit: "out", durationMilliseconds: 200)
        #expect(differ.diff(
            old: element(transitionPhases: phases),
            new: element(transitionPhases: phases)
        ) == [])
    }

    @Test func droppingTransitionPhasesClearsThem() {
        #expect(differ.diff(
            old: element(transitionPhases: .init(enter: "in", exit: "out", durationMilliseconds: 200)),
            new: element()
        ) == [.setTransitionPhases(path: NodePath(), phases: nil)])
    }

}
