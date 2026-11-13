//
//  ViewStylesheetTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 14/11/2026.
//

import Testing
@_spi(Runtime) @_spi(Rendering) import SwiftWebUI
@testable import SwiftWebUIRuntime

private final class Theme {
    var sheets: [DocumentStylesheet]
    init(_ sheets: [DocumentStylesheet]) { self.sheets = sheets }
}

/// One element per stylesheet, each placing its own.
private struct Themed: View {
    let theme: Theme

    var body: some View {
        VStack {
            Text("content")
            ForEach(theme.sheets.indices, id: { $0 }) { index in
                Text("sheet").stylesheet(theme.sheets[index])
            }
        }
    }
}

private func headDescription(_ backend: FakeDOMBackend) -> [String] {
    backend.head.children.map { node in
        node.tagName == "style" ? "style \(node.text ?? "")" : "link \(node.attributes["href"] ?? "")"
    }
}

extension RuntimeMountTests {
    @Suite struct ViewStylesheetTests {

        @Test func aViewStylesheetIsInstalledKeptAndReplaced() {
            let theme = Theme([.external("a.css"), .inline("b")])
            let backend = FakeDOMBackend()
            let root = MountedRoot(container: backend.root, backend: backend) {
                ViewNodeToWebNodeLowerer().lowerView(Themed(theme: theme).makeViewNode())
            }
            defer { root.stop() }

            root.start()
            #expect(headDescription(backend) == ["link a.css", "style b"])
            let first = backend.head.children[0]

            root.invalidate()
            #expect(backend.head.children[0] === first)
            #expect(headDescription(backend) == ["link a.css", "style b"])

            theme.sheets = [.external("a.css"), .inline("c")]
            root.invalidate()
            #expect(backend.head.children[0] === first)
            #expect(headDescription(backend) == ["link a.css", "style c"])
        }

        @Test func stoppingRemovesViewStylesheets() {
            let backend = FakeDOMBackend()
            let root = MountedRoot(container: backend.root, backend: backend) {
                ViewNodeToWebNodeLowerer().lowerView(Text("x").stylesheet(.inline("b")).makeViewNode())
            }

            root.start()
            #expect(headDescription(backend) == ["style b"])
            root.stop()
            #expect(backend.head.children.isEmpty)
        }
    }
}
