//
//  TransitionTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 28/08/2026.
//

import Testing
@_spi(Rendering) import SwiftWebUI
@testable import SwiftWebUIRuntime

@Suite struct TransitionTests {
    private let phases = TransitionPhases(enter: "fade-in", exit: "fade-out", durationMilliseconds: 200)

    // MARK: - Entering

    @Test func theEnterClassLandsOnTheFrameAfterInsertion() {
        let backend = FakeDOMBackend()
        _ = mounted(element(transitionPhases: phases), backend: backend)
        let node = backend.root.children[0]

        // Applying it in the same frame is the classic no-op: the browser never
        // paints the pre-transition state, so there is nothing to transition
        // from.
        #expect(node.attributes["class"] == nil)

        backend.runScheduledWork()

        #expect(node.attributes["class"] == "fade-in")
    }

    @Test func theEnterClassJoinsTheElementsOwnClasses() {
        let backend = FakeDOMBackend()
        _ = mounted(
            element(attributes: [.init(name: "class", value: "card")], transitionPhases: phases),
            backend: backend
        )
        let node = backend.root.children[0]

        #expect(node.attributes["class"] == "card")
        backend.runScheduledWork()
        #expect(node.attributes["class"] == "card fade-in")
    }

    @Test func rewritingClassMidTransitionKeepsThePhase() throws {
        let backend = FakeDOMBackend()
        var tree = mounted(
            element(attributes: [.init(name: "class", value: "card")], transitionPhases: phases),
            backend: backend
        )
        backend.runScheduledWork()
        let node = backend.root.children[0]

        try applier(backend).apply(
            [.setAttribute(path: NodePath(), name: "class", value: "card selected")],
            to: &tree
        )

        #expect(node.attributes["class"] == "card selected fade-in")
    }

    @Test func removingClassMidTransitionKeepsThePhase() throws {
        let backend = FakeDOMBackend()
        var tree = mounted(
            element(attributes: [.init(name: "class", value: "card")], transitionPhases: phases),
            backend: backend
        )
        backend.runScheduledWork()

        try applier(backend).apply([.removeAttribute(path: NodePath(), name: "class")], to: &tree)

        #expect(backend.root.children[0].attributes["class"] == "fade-in")
    }

    @Test func anElementWithoutPhasesSchedulesNothing() {
        let backend = FakeDOMBackend()
        _ = mounted(element(), backend: backend)

        #expect(!backend.operations.contains("requestAnimationFrame"))
    }

    // MARK: - Leaving

    @Test func aLeavingElementStaysInTheDocumentWearingItsExitClass() throws {
        let backend = FakeDOMBackend()
        var tree = mounted(
            element(children: [element("div", transitionPhases: phases)]),
            backend: backend
        )
        backend.runScheduledWork()
        let parent = backend.root.children[0]
        let leaving = parent.children[0]

        try applier(backend).apply([.removeChild(parent: NodePath(), index: 0)], to: &tree)

        // Still on screen, so the exit has a frame to run in.
        #expect(parent.children.count == 1)
        #expect(leaving.attributes["class"] == "fade-out")

        backend.runScheduledWork()

        #expect(parent.children.isEmpty)
    }

    @Test func aLeavingElementWaitsExactlyItsOwnDuration() throws {
        let backend = FakeDOMBackend()
        var tree = mounted(
            element(children: [
                element("div", transitionPhases: .init(enter: "in", exit: "out", durationMilliseconds: 320)),
            ]),
            backend: backend
        )
        backend.operations.removeAll()

        try applier(backend).apply([.removeChild(parent: NodePath(), index: 0)], to: &tree)

        #expect(backend.operations.contains("setTimeout 320"))
    }

    @Test func anElementWithoutPhasesIsRemovedImmediately() throws {
        let backend = FakeDOMBackend()
        var tree = mounted(element(children: [element("div")]), backend: backend)
        let parent = backend.root.children[0]

        try applier(backend).apply([.removeChild(parent: NodePath(), index: 0)], to: &tree)

        #expect(parent.children.isEmpty)
        #expect(!backend.operations.contains { $0.hasPrefix("setTimeout") })
    }

    // MARK: - The positional-path trap

    @Test func laterSiblingsKeepTheirIndicesWhileAnElementIsLeaving() throws {
        let backend = FakeDOMBackend()
        var tree = mounted(
            element(children: [
                element("div", transitionPhases: phases),
                element("span", children: [.text("first")]),
                element("span", children: [.text("second")]),
            ]),
            backend: backend
        )
        backend.runScheduledWork()
        let applier = applier(backend)

        // Remove index 0 and, in the same batch, patch what is now index 0 and 1.
        // A leaving node that still counted would send both to the wrong element.
        try applier.apply([
            .removeChild(parent: NodePath(), index: 0),
            .setText(path: NodePath([0, 0]), value: "first patched"),
            .setText(path: NodePath([1, 0]), value: "second patched"),
        ], to: &tree)

        let parent = backend.root.children[0]
        #expect(parent.children.count == 3)
        #expect(parent.children[1].children[0].text == "first patched")
        #expect(parent.children[2].children[0].text == "second patched")

        backend.runScheduledWork()

        #expect(parent.children.count == 2)
        #expect(parent.children[0].children[0].text == "first patched")
    }

    @Test func aNewChildMountedWhileAnotherIsLeavingIsNotConfusedWithIt() throws {
        let backend = FakeDOMBackend()
        var tree = mounted(
            element(children: [element("div", transitionPhases: phases)]),
            backend: backend
        )
        backend.runScheduledWork()
        let applier = applier(backend)

        try applier.apply([.removeChild(parent: NodePath(), index: 0)], to: &tree)
        try applier.apply(
            [.insertChild(parent: NodePath(), index: 0, node: element("div", transitionPhases: phases))],
            to: &tree
        )

        // A re-render mounts a fresh handle, so the leaving one is nobody's
        // business but its own timer's.
        let parent = backend.root.children[0]
        #expect(parent.children.count == 2)

        backend.runScheduledWork()

        #expect(parent.children.count == 1)
        #expect(parent.children[0].attributes["class"] == "fade-in")
    }

    // MARK: - Reduced motion

    @Test func aReducedMotionReaderEntersImmediately() {
        let backend = FakeDOMBackend()
        backend.reducedMotion = true

        _ = mounted(element(transitionPhases: phases), backend: backend)

        #expect(backend.root.children[0].attributes["class"] == "fade-in")
        #expect(!backend.operations.contains("requestAnimationFrame"))
    }

    @Test func aReducedMotionReaderDoesNotWaitOutTheDuration() throws {
        let backend = FakeDOMBackend()
        backend.reducedMotion = true
        var tree = mounted(
            element(children: [element("div", transitionPhases: phases)]),
            backend: backend
        )
        let parent = backend.root.children[0]

        try applier(backend).apply([.removeChild(parent: NodePath(), index: 0)], to: &tree)

        // Skipping the animation but keeping the wait is the worst of both.
        #expect(parent.children.isEmpty)
        #expect(!backend.operations.contains { $0.hasPrefix("setTimeout") })
    }

    // MARK: - Cancellation

    @Test func aStoppedRootDropsWorkThatWouldFireAgainstVanishedNodes() {
        let backend = FakeDOMBackend()
        let scheduler = TransitionScheduler(backend: backend)
        var ran = 0
        scheduler.after(milliseconds: 200) { ran += 1 }
        #expect(scheduler.hasPendingWork)

        scheduler.cancelAll()
        backend.runScheduledWork()

        #expect(ran == 0)
        #expect(!scheduler.hasPendingWork)
        #expect(backend.cancelledWork == 1)
    }

    @Test func workThatHasRunIsNoLongerPending() {
        let backend = FakeDOMBackend()
        let scheduler = TransitionScheduler(backend: backend)
        var ran = 0
        scheduler.after(milliseconds: 200) { ran += 1 }

        backend.runScheduledWork()

        #expect(ran == 1)
        #expect(!scheduler.hasPendingWork)
    }

    private func applier(_ backend: FakeDOMBackend) -> DOMPatchApplier<FakeDOMBackend> {
        DOMPatchApplier(
            backend: backend,
            container: backend.root,
            scrollLock: ScrollLock(backend: backend),
            transitions: TransitionScheduler(backend: backend)
        )
    }
}
