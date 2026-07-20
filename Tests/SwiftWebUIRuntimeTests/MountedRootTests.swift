import Testing
@_spi(Runtime) @_spi(Rendering) import SwiftWebUI
@testable import SwiftWebUIRuntime

@Suite(.serialized) struct MountedRootTests {
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
}
