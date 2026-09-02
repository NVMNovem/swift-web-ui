//
//  MountedRootTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

import Testing
@_spi(Runtime) @_spi(Rendering) import SwiftWebUI
@testable import SwiftWebUIRuntime

extension RuntimeMountTests {
    @Suite struct MountedRootTests {
        @Test func stateInvalidationRebuildsAndUpdatesOnlyText() {
            final class Model { @State var count = 0 }
            let model = Model()
            let backend = FakeDOMBackend()
            let root = MountedRoot(container: backend.root, backend: backend) {
                backend.buildCount += 1
                return element("span", children: [.text(String(model.count))])
            }
            defer { root.stop() }

            root.start()
            let span = backend.root.children[0]
            let text = span.children[0]
            backend.operations.removeAll()
            model.count += 1

            #expect(backend.buildCount == 2)
            #expect(backend.operations == ["setText \(text.id) 1"])
            #expect(backend.root.children[0] === span)
            #expect(span.children[0] === text)
        }

        @Test func actionReregistrationKeepsButtonMounted() {
            let backend = FakeDOMBackend()
            var generation = 0
            let root = MountedRoot(container: backend.root, backend: backend) {
                generation += 1
                return element("button", children: [.text("button")], action: .closure {})
            }
            defer { root.stop() }

            root.start()
            let button = backend.root.children[0]
            backend.operations.removeAll()
            root.invalidate()

            #expect(generation == 2)
            #expect(backend.root.children[0] === button)
            #expect(backend.operations == ["removeAction \(button.id) 1", "setAction \(button.id) 2"])
        }

        @Test func navigationTitleReconcilesAndRestoresTheHostTitle() {
            let backend = FakeDOMBackend()
            var title: String? = "Projects"
            let root = MountedRoot(container: backend.root, backend: backend) {
                LoweredView(
                    webNode: element("main", children: [.text("Content")]),
                    documentMetadata: .init(navigationTitle: title)
                )
            }

            root.start()
            #expect(backend.documentTitle == "Projects")

            backend.operations.removeAll()
            title = "Settings"
            root.invalidate()
            #expect(backend.operations == ["setDocumentTitle Settings"])
            #expect(backend.documentTitle == "Settings")

            backend.operations.removeAll()
            title = nil
            root.invalidate()
            #expect(backend.operations == ["setDocumentTitle Host Document"])
            #expect(backend.documentTitle == "Host Document")

            backend.operations.removeAll()
            title = "Profile"
            root.invalidate()
            backend.operations.removeAll()
            root.stop()
            #expect(backend.operations == ["setDocumentTitle Host Document"])
            #expect(backend.documentTitle == "Host Document")
        }

        @Test func navigationIconReconcilesAndRemovesItsManagedHeadLink() {
            let backend = FakeDOMBackend()
            var icon: NavigationIcon? = .svg("<svg viewBox=\"0 0 16 16\"/>")
            let root = MountedRoot(container: backend.root, backend: backend) {
                LoweredView(
                    webNode: element("main", children: [.text("Content")]),
                    documentMetadata: .init(navigationIcon: icon)
                )
            }
            defer { root.stop() }

            root.start()
            #expect(backend.head.children.count == 1)
            let handle = backend.head.children[0]
            #expect(handle.tagName == "link")
            #expect(handle.attributes == [
                "rel": "icon",
                "href": "data:image/svg+xml,%3Csvg%20viewBox%3D%220%200%2016%2016%22%2F%3E",
                "type": "image/svg+xml",
            ])

            backend.operations.removeAll()
            icon = .url("/settings.png")
            root.invalidate()
            #expect(backend.head.children.count == 1)
            #expect(backend.head.children[0] === handle)
            #expect(handle.attributes == ["rel": "icon", "href": "/settings.png"])
            #expect(backend.operations == [
                "documentHead",
                "setAttribute \(handle.id) href=/settings.png",
                "removeAttribute \(handle.id) type",
            ])

            backend.operations.removeAll()
            icon = nil
            root.invalidate()
            #expect(backend.head.children.isEmpty)
            #expect(backend.operations == [
                "documentHead",
                "remove \(handle.id) from -1",
            ])

            icon = .url("/profile.png")
            root.invalidate()
            #expect(backend.head.children.count == 1)
            let profileHandle = backend.head.children[0]
            backend.operations.removeAll()
            root.stop()
            #expect(backend.head.children.isEmpty)
            #expect(backend.operations == [
                "documentHead",
                "remove \(profileHandle.id) from -1",
            ])
        }
    }
}
