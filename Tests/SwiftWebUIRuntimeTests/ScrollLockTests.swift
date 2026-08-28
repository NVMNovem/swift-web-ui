//
//  ScrollLockTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 28/08/2026.
//

import Testing
@_spi(Rendering) import SwiftWebUI
@testable import SwiftWebUIRuntime

@Suite struct ScrollLockTests {
    @Test func firstAcquireStopsTheBodyScrolling() {
        let backend = FakeDOMBackend()
        let lock = ScrollLock(backend: backend)

        lock.acquire()

        #expect(lock.isLocked)
        #expect(backend.body.styles["overflow"] == "hidden")
    }

    @Test func lastReleaseLetsTheBodyScrollAgain() {
        let backend = FakeDOMBackend()
        let lock = ScrollLock(backend: backend)

        lock.acquire()
        lock.release()

        #expect(!lock.isLocked)
        #expect(backend.body.styles["overflow"] == nil)
    }

    @Test func nestedHoldersRestoreScrollingExactlyOnce() {
        let backend = FakeDOMBackend()
        let lock = ScrollLock(backend: backend)

        lock.acquire()
        lock.acquire()
        lock.release()

        // One holder is still presented, so the page must stay locked.
        #expect(lock.isLocked)
        #expect(backend.body.styles["overflow"] == "hidden")

        lock.release()

        #expect(!lock.isLocked)
        #expect(backend.body.styles["overflow"] == nil)

        // The body was touched exactly twice: once locking, once restoring.
        let bodyWrites = backend.operations.filter { $0.contains("\(backend.body.id) overflow") }
        #expect(bodyWrites.count == 2)
    }

    @Test func releaseRestoresThePreviousInlineValueRatherThanGuessing() {
        let backend = FakeDOMBackend()
        backend.setStyle(name: "overflow", value: "auto", on: backend.body)
        let lock = ScrollLock(backend: backend)

        lock.acquire()
        #expect(backend.body.styles["overflow"] == "hidden")

        lock.release()
        #expect(backend.body.styles["overflow"] == "auto")
    }

    @Test func anUnbalancedReleaseIsIgnored() {
        let backend = FakeDOMBackend()
        let lock = ScrollLock(backend: backend)

        lock.release()
        #expect(!lock.isLocked)

        lock.acquire()
        lock.release()
        lock.release()

        #expect(!lock.isLocked)
        #expect(backend.body.styles["overflow"] == nil)
    }

    @Test func anUnavailableBodyLeavesNothingToRelease() {
        let backend = FakeDOMBackend()
        backend.failDocumentBody = true
        let lock = ScrollLock(backend: backend)

        lock.acquire()
        #expect(!lock.isLocked)

        // Releasing a lock that never took hold must not write to the body.
        lock.release()
        #expect(backend.body.styles["overflow"] == nil)
    }
}

@Suite struct RuntimeDialogStylesheetTests {
    @Test func theRuntimeSheetIsInstalledAheadOfEveryApplicationSheet() throws {
        let backend = FakeDOMBackend()
        let resources = RuntimeResources(stylesheets: [.external("app.css")])

        _ = try RuntimeStylesheetInstaller(backend: backend)
            .install(resources.withRuntimeStylesheets())

        // Order is the point: the runtime's defaults come first so an
        // application's rules win.
        #expect(backend.head.children.map(\.tagName) == ["style", "link"])
        #expect(backend.head.children[0].text == RuntimeDialogStylesheet.css)
        #expect(backend.head.children[1].attributes["href"] == "app.css")
    }

    @Test func theBackdropIsANamedRuleThemedThroughACustomProperty() {
        // `::backdrop` is a pseudo-element and cannot be reached by an inline
        // style, so it has to live in a stylesheet.
        #expect(RuntimeDialogStylesheet.css.contains("::backdrop"))
        #expect(RuntimeDialogStylesheet.css.contains("--swiftwebui-dialog-backdrop"))
        #expect(RuntimeDialogStylesheet.css.contains(".swiftwebui-dialog"))
    }

    @Test func anApplicationWithNoStylesheetsStillGetsTheRuntimeSheet() throws {
        let backend = FakeDOMBackend()

        _ = try RuntimeStylesheetInstaller(backend: backend)
            .install(RuntimeResources().withRuntimeStylesheets())

        #expect(backend.head.children.count == 1)
        #expect(backend.head.children[0].tagName == "style")
    }
}
