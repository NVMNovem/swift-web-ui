//
//  DropTargetSessionTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

import Testing
@_spi(Runtime) @_spi(Rendering) import SwiftWebUI
@testable import SwiftWebUIRuntime

// MARK: - Fixtures

private final class Journal {
    var entries: [String] = []
}

private struct RecordingDelegate: DropDelegate {
    let journal: Journal
    var welcomes = true
    var proposal: DropProposal?

    func validateDrop(info: DropInfo) -> Bool {
        journal.entries.append("validate")
        return welcomes
    }

    func dropEntered(info: DropInfo) { journal.entries.append("entered") }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        journal.entries.append("updated")
        return proposal
    }

    func dropExited(info: DropInfo) { journal.entries.append("exited") }

    func performDrop(info: DropInfo) -> Bool {
        journal.entries.append("perform")
        return true
    }
}

/// A destination whose look depends on whether a drag is over it.
private struct Inbox: View {
    @State private var isTargeted = false
    let received: (String) -> Void

    var body: some View {
        Div {
            Text(isTargeted ? "Release to add" : "Drop here")
        }
        .onDrop(of: [.plainText], isTargeted: $isTargeted) { providers in
            providers.first?.loadObject(ofClass: String.self) { if let value = $0 { received(value) } }
            return true
        }
    }
}

private let plainText = DropInfo(location: .zero, contentTypes: [.plainText])
private let json = DropInfo(location: .zero, contentTypes: [.json])

private func dropped(_ value: String) -> DropInfo {
    DropInfo(
        location: .zero,
        contentTypes: [.plainText],
        representations: [.init(contentType: .plainText, value: value)]
    )
}

private func texts(_ node: FakeDOMNode) -> [String] {
    var found: [String] = []
    if let text = node.text { found.append(text) }
    for child in node.children { found.append(contentsOf: texts(child)) }
    return found
}

// MARK: - Tests

@Suite struct DropTargetSessionTests {
    @Test func aWelcomeDragEntersOnceUpdatesAsItMovesAndDrops() {
        let journal = Journal()
        let session = DropTargetSession(target: DropTarget(of: [.plainText], delegate: RecordingDelegate(journal: journal)))

        #expect(session.handle(.enter, info: plainText) == .copy)
        #expect(session.handle(.over, info: plainText) == .copy)
        #expect(session.handle(.over, info: plainText) == .copy)
        #expect(session.handle(.drop, info: dropped("x")) == .copy)

        #expect(journal.entries == ["validate", "entered", "updated", "updated", "updated", "perform"])
        #expect(!session.isActive)
    }

    @Test func anUnsupportedDragIsRefusedWithoutAskingTheDelegate() {
        let journal = Journal()
        let session = DropTargetSession(target: DropTarget(of: [.plainText], delegate: RecordingDelegate(journal: journal)))

        #expect(session.handle(.enter, info: json) == nil)
        #expect(session.handle(.over, info: json) == nil)
        #expect(session.handle(.leave, info: json) == nil)

        #expect(journal.entries.isEmpty)
    }

    @Test func aDragTheDelegateRefusesIsNeitherEnteredNorExited() {
        let journal = Journal()
        let session = DropTargetSession(
            target: DropTarget(of: [.plainText], delegate: RecordingDelegate(journal: journal, welcomes: false))
        )

        #expect(session.handle(.enter, info: plainText) == nil)
        #expect(session.handle(.over, info: plainText) == nil)
        #expect(session.handle(.leave, info: plainText) == nil)

        #expect(journal.entries == ["validate"])
    }

    @Test func theDelegatesProposalIsPassedOn() {
        let journal = Journal()
        let forbidding = DropTargetSession(target: DropTarget(
            of: [.plainText],
            delegate: RecordingDelegate(journal: journal, proposal: DropProposal(operation: .forbidden))
        ))
        let moving = DropTargetSession(target: DropTarget(
            of: [.plainText],
            delegate: RecordingDelegate(journal: journal, proposal: DropProposal(operation: .move))
        ))

        #expect(forbidding.handle(.over, info: plainText) == .forbidden)
        #expect(moving.handle(.over, info: plainText) == .move)
    }

    @Test func leavingExitsAndAMissedLeaveHealsOnTheNextMove() {
        let journal = Journal()
        let session = DropTargetSession(target: DropTarget(of: [.plainText], delegate: RecordingDelegate(journal: journal)))

        _ = session.handle(.enter, info: plainText)
        _ = session.handle(.leave, info: plainText)
        #expect(journal.entries == ["validate", "entered", "updated", "exited"])

        // A `dragover` without a `dragenter` — its target was replaced mid-drag —
        // enters again rather than being refused.
        journal.entries.removeAll()
        #expect(session.handle(.over, info: plainText) == .copy)
        #expect(journal.entries == ["validate", "entered", "updated"])
    }
}

extension RuntimeMountTests {
    @Suite struct DropTargetMountTests {
        @Test func aRerenderMidDragKeepsTheDragAndTheDropStillLands() {
            var received: [String] = []
            let backend = FakeDOMBackend()
            let root = MountedRoot(container: backend.root, backend: backend) {
                ViewNodeToWebNodeLowerer().lowerView(Inbox(received: { received.append($0) }).makeViewNode())
            }
            defer { root.stop() }
            root.start()
            let inbox = backend.root.children[0]
            #expect(texts(inbox) == ["Drop here"])

            // Entering sets `isTargeted`, which rerenders while the drag is in progress.
            #expect(inbox.deliverDrag(.enter, plainText) == .copy)
            backend.runScheduledWork()
            #expect(texts(inbox) == ["Release to add"])
            #expect(backend.root.children[0] === inbox)
            #expect(!backend.operations.contains { $0.hasPrefix("removeDropAction") })

            #expect(inbox.deliverDrag(.over, plainText) == .copy)
            #expect(inbox.deliverDrag(.drop, dropped("card-3")) == .copy)

            #expect(received == ["card-3"])
            backend.runScheduledWork()
            #expect(texts(inbox) == ["Drop here"])
        }

        @Test func aMountedDragSourceHandsOverItsContentWhenTheDragStarts() {
            var title = "Draft"
            let backend = FakeDOMBackend()
            let root = MountedRoot(container: backend.root, backend: backend) {
                ViewNodeToWebNodeLowerer().lowerView(
                    Text("Card").onDrag { ItemProvider(object: title) }.makeViewNode()
                )
            }
            defer { root.stop() }
            root.start()
            let card = backend.root.children[0]

            #expect(card.attributes["draggable"] == "true")
            title = "Final"
            #expect(card.startDrag() == [.init(contentType: .plainText, value: "Final")])
        }
    }
}
