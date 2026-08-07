//
//  RuntimeStylesheetInstallerTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 22/07/2026.
//

import Testing
@_spi(Runtime) @_spi(Rendering) import SwiftWebUI
@testable import SwiftWebUIRuntime

extension RuntimeMountTests {
    @Suite struct RuntimeStylesheetInstallerTests {
        @Test func noResourcesInstallNothing() throws {
            let backend = FakeDOMBackend()

            let installed = try installer(backend).install(.init())

            #expect(installed.stylesheetHandles.isEmpty)
            #expect(backend.head.children.isEmpty)
            #expect(backend.operations.isEmpty)
        }

        @Test func externalStylesheetCreatesOneLinkAndPreservesHref() throws {
            let backend = FakeDOMBackend()

            let installed = try installer(backend).install(.init(stylesheets: [
                .external("assets/theme.css?mode=runtime#rules"),
            ]))

            #expect(installed.stylesheetHandles.count == 1)
            #expect(backend.head.children.count == 1)
            #expect(backend.head.children[0].tagName == "link")
            #expect(backend.head.children[0].attributes["rel"] == "stylesheet")
            #expect(backend.head.children[0].attributes["href"] == "assets/theme.css?mode=runtime#rules")
        }

        @Test func multipleExternalStylesheetsPreserveOrder() throws {
            let backend = FakeDOMBackend()

            _ = try installer(backend).install(.init(stylesheets: [
                .external("base.css"),
                .external("theme.css"),
            ]))

            #expect(backend.head.children.map { $0.attributes["href"] } == ["base.css", "theme.css"])
        }

        @Test func inlineStylesheetCreatesStyleAndPreservesContent() throws {
            let backend = FakeDOMBackend()
            let css = ":root { --accent: teal; }\n.card:hover { color: var(--accent); }"

            _ = try installer(backend).install(.init(stylesheets: [.inline(css)]))

            #expect(backend.head.children.count == 1)
            #expect(backend.head.children[0].tagName == "style")
            #expect(backend.head.children[0].text == css)
        }

        @Test func mixedStylesheetsPreserveDeclarationOrder() throws {
            let backend = FakeDOMBackend()

            _ = try installer(backend).install(.init(stylesheets: [
                .external("first.css"),
                .inline(".middle {}"),
                .external("last.css"),
            ]))

            #expect(backend.head.children.map(\.tagName) == ["link", "style", "link"])
            #expect(backend.head.children[0].attributes["href"] == "first.css")
            #expect(backend.head.children[1].text == ".middle {}")
            #expect(backend.head.children[2].attributes["href"] == "last.css")
        }

        @Test func stateInvalidationDoesNotDuplicateResources() throws {
            final class Model { @State var count = 0 }
            let model = Model()
            let backend = FakeDOMBackend()
            let installed = try installer(backend).install(.init(stylesheets: [.external("style.css")]))
            let root = MountedRoot(
                container: backend.root,
                backend: backend,
                installedResources: installed
            ) {
                element("span", children: [.text(String(model.count))])
            }
            defer { root.stop() }

            root.start()
            model.count += 1
            model.count += 1

            #expect(backend.head.children.count == 1)
            #expect(root.installedResources.stylesheetHandles.count == 1)
        }

        @Test func installationIsIndependentFromDOMReconciliation() throws {
            let backend = FakeDOMBackend()
            let installed = try installer(backend).install(.init(stylesheets: [.external("style.css")]))
            let headOperations = backend.operations
            let root = MountedRoot(
                container: backend.root,
                backend: backend,
                installedResources: installed
            ) {
                element("span", children: [.text("value")])
            }
            defer { root.stop() }

            root.start()
            root.invalidate()

            #expect(backend.operations.filter { headOperations.contains($0) } == headOperations)
            #expect(backend.head.children.count == 1)
        }

        @Test func mountedRootRetainsInstalledHandles() throws {
            let backend = FakeDOMBackend()
            var installed: InstalledRuntimeResources<FakeDOMNode>? = try installer(backend)
                .install(.init(stylesheets: [.external("style.css")]))
            let handleID = installed?.stylesheetHandles[0].id
            let root = MountedRoot(
                container: backend.root,
                backend: backend,
                installedResources: installed!
            ) {
                element()
            }

            installed = nil

            #expect(root.installedResources.stylesheetHandles.count == 1)
            #expect(root.installedResources.stylesheetHandles[0].id == handleID)
        }

        @Test func installationErrorIsThrownAndPreviouslyInstalledNodesAreRolledBack() {
            let backend = FakeDOMBackend()
            backend.failResourceTextInstallation = true

            #expect(throws: FakeDOMBackendError.self) {
                try installer(backend).install(.init(stylesheets: [
                    .external("first.css"),
                    .inline("broken"),
                ]))
            }
            #expect(backend.head.children.isEmpty)
        }

        private func installer(
            _ backend: FakeDOMBackend
        ) -> RuntimeStylesheetInstaller<FakeDOMBackend> {
            RuntimeStylesheetInstaller(backend: backend)
        }
    }
}
