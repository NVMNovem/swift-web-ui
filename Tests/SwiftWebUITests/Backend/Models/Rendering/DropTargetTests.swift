//
//  DropTargetTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

import Testing
@_spi(Rendering) import SwiftWebUI

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

private struct MinimalDelegate: DropDelegate {
    func performDrop(info: DropInfo) -> Bool { true }
}

@Suite struct DropTargetTests {
    private let text = DropInfo(location: .zero, contentTypes: [.plainText])

    @Test func aDragOfAnUnsupportedTypeNeverReachesTheDelegate() {
        let journal = Journal()
        let target = DropTarget(of: [.json], delegate: RecordingDelegate(journal: journal))

        #expect(!target.validateDrop(info: text))
        #expect(journal.entries.isEmpty)
    }

    @Test func theDelegateDecidesForASupportedType() {
        let journal = Journal()
        let refusing = DropTarget(of: [.text], delegate: RecordingDelegate(journal: journal, welcomes: false))

        #expect(!refusing.validateDrop(info: text))
        #expect(journal.entries == ["validate"])
    }

    @Test func noProposalMeansCopy() {
        let journal = Journal()
        let target = DropTarget(of: [.plainText], delegate: RecordingDelegate(journal: journal))
        let moving = DropTarget(
            of: [.plainText],
            delegate: RecordingDelegate(journal: journal, proposal: DropProposal(operation: .move))
        )

        #expect(target.dropUpdated(info: text) == .copy)
        #expect(moving.dropUpdated(info: text) == .move)
    }

    @Test func aDelegateNeedsOnlyPerformDrop() {
        let target = DropTarget(of: [.plainText], delegate: MinimalDelegate())

        #expect(target.validateDrop(info: text))
        target.dropEntered(info: text)
        #expect(target.dropUpdated(info: text) == .copy)
        target.dropExited(info: text)
        #expect(target.performDrop(info: text))
    }
}
