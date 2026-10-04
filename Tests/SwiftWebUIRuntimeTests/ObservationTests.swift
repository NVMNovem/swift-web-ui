//
//  ObservationTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 29/09/2026.
//

import Observation
import Testing
@_spi(Runtime) @_spi(Rendering) import SwiftWebUI
@testable import SwiftWebUIRuntime

@Observable
private final class Counter {
    var count = 0
    var unread = 0
}

extension RuntimeMountTests {
    @Suite struct ObservationTests {

        @Test func anObservedWriteRebuildsOnTheNextTurn() {
            let counter = Counter()
            let backend = FakeDOMBackend()
            let root = MountedRoot(container: backend.root, backend: backend) {
                backend.buildCount += 1
                return element("span", children: [.text(String(counter.count))])
            }
            defer { root.stop() }

            root.start()
            let text = backend.root.children[0].children[0]
            backend.operations.removeAll()

            counter.count = 1
            // Observation reports from `willSet`, so nothing is drawn yet.
            #expect(backend.buildCount == 1)
            #expect(backend.operations == ["setTimeout 0"])

            backend.runScheduledWork()
            #expect(backend.buildCount == 2)
            #expect(backend.operations == ["setTimeout 0", "setText \(text.id) 1"])
        }

        @Test func severalWritesInOneTurnShareOneRebuild() {
            let counter = Counter()
            let backend = FakeDOMBackend()
            let root = MountedRoot(container: backend.root, backend: backend) {
                backend.buildCount += 1
                return element("span", children: [.text("\(counter.count)")])
            }
            defer { root.stop() }

            root.start()
            let builds = backend.buildCount
            counter.count = 1
            counter.count = 2
            counter.count = 3
            #expect(backend.scheduled.count == 1)

            backend.runScheduledWork()
            #expect(backend.buildCount == builds + 1)
            #expect(backend.root.children[0].children[0].text == "3")
        }

        @Test func aPropertyTheBuildNeverReadDoesNotRebuild() {
            let counter = Counter()
            let backend = FakeDOMBackend()
            let root = MountedRoot(container: backend.root, backend: backend) {
                element("span", children: [.text("\(counter.count)")])
            }
            defer { root.stop() }

            root.start()
            counter.unread = 1
            #expect(backend.scheduled.isEmpty)
        }

        @Test func aStateWriteInTheSameTurnMakesTheScheduledRebuildRedundant() {
            final class Model { @State var flag = false }
            let model = Model()
            let counter = Counter()
            let backend = FakeDOMBackend()
            let root = MountedRoot(container: backend.root, backend: backend) {
                backend.buildCount += 1
                return element("span", children: [.text("\(counter.count) \(model.flag)")])
            }
            defer { root.stop() }

            root.start()
            counter.count = 1
            model.flag = true               // rebuilds now, reading count == 1
            let builds = backend.buildCount

            backend.runScheduledWork()
            #expect(backend.buildCount == builds)
            #expect(backend.root.children[0].children[0].text == "1 true")
        }

        @Test func aStaleBuildsRegistrationIsIgnored() {
            final class Model { @State var flag = false }
            let model = Model()
            let counter = Counter()
            let backend = FakeDOMBackend()
            let root = MountedRoot(container: backend.root, backend: backend) {
                // The second build stops reading the counter, as a screen that
                // navigated away would.
                element("span", children: [.text(model.flag ? "away" : "\(counter.count)")])
            }
            defer { root.stop() }

            root.start()
            model.flag = true
            counter.count = 1               // only the first build's registration fires
            #expect(backend.scheduled.isEmpty)
        }

        @Test func stoppingCancelsARebuildNotYetRun() {
            let counter = Counter()
            let backend = FakeDOMBackend()
            let root = MountedRoot(container: backend.root, backend: backend) {
                backend.buildCount += 1
                return element("span", children: [.text("\(counter.count)")])
            }

            root.start()
            counter.count = 1
            let builds = backend.buildCount
            root.stop()
            backend.runScheduledWork()

            #expect(backend.cancelledWork == 1)
            #expect(backend.buildCount == builds)
            counter.count = 2
            #expect(backend.scheduled.isEmpty)
        }
    }
}
