//
//  MountedRoot.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

@_spi(Runtime) @_spi(Rendering) import SwiftWebUI

final class MountedRoot<Backend: DOMBackend> {
    typealias Node = MountedNode<Backend.Node, Backend.ActionRegistration>

    private let container: Backend.Node
    private let build: () -> WebNode
    private let backend: Backend
    private let differ = WebNodeDiffer()
    private let configuration: SwiftWebUIRuntimeConfiguration
    let installedResources: InstalledRuntimeResources<Backend.Node>
    private var previousWebNode: WebNode?
    private var mountedNode: Node?

    /// Owns `@State` storage for everything mounted under this root.
    let stateSlots = StateSlotStore()
    private var isRebuilding = false

    deinit {
        // Slots hold their boxes with a manual retain, so a discarded root must
        // release them even if `stop()` was never called.
        stateSlots.releaseAll()
    }

    init(
        container: Backend.Node,
        backend: Backend,
        configuration: SwiftWebUIRuntimeConfiguration = .init(),
        installedResources: InstalledRuntimeResources<Backend.Node> = .init(),
        build: @escaping () -> WebNode
    ) {
        self.container = container
        self.backend = backend
        self.configuration = configuration
        self.installedResources = installedResources
        self.build = build
    }

    func start() {
        StateSlotStorage.install(stateSlots)
        ViewInvalidation.install { [self] in
            invalidate()
        }
        initialMount()
    }

    func stop() {
        ViewInvalidation.clear()
        StateSlotStorage.clear()
        stateSlots.releaseAll()
    }

    /// Rebuilds the presentation tree, reclaiming state for views that disappeared.
    private func buildTrackingState() -> WebNode {
        isRebuilding = true
        stateSlots.beginBuild()
        defer {
            stateSlots.endBuild()
            isRebuilding = false
        }
        return build()
    }

    func invalidate() {
        // A state write while `body` is running would restart the liveness sweep
        // mid-traversal and release slots the traversal has not reached yet. The
        // resulting tree is built from the already-updated state either way.
        guard !isRebuilding else { return }
        guard var mountedNode, previousWebNode != nil else {
            initialMount()
            return
        }
        let newWebNode = buildTrackingState()
        let patches = differ.diff(old: previousWebNode!, new: newWebNode)
        let applier = DOMPatchApplier(
            backend: backend,
            container: container,
            loggingEnabled: configuration.reconciliationLogging
        )
        do {
            try applier.apply(patches, to: &mountedNode)
            self.mountedNode = mountedNode
        } catch {
            print("[SwiftWebUIRuntime] reconciliation fallback: \(error)")
            applier.recursivelyReleaseActions(in: mountedNode)
            backend.removeAllChildren(from: container)
            let replacement = DOMMounter(backend: backend).mount(newWebNode)
            appendToContainer(replacement)
            self.mountedNode = replacement
        }
        previousWebNode = newWebNode
    }

    private func initialMount() {
        if let mountedNode {
            DOMPatchApplier(backend: backend, container: container)
                .recursivelyReleaseActions(in: mountedNode)
        }
        backend.removeAllChildren(from: container)
        let webNode = buildTrackingState()
        let mountedNode = DOMMounter(backend: backend).mount(webNode)
        appendToContainer(mountedNode)
        previousWebNode = webNode
        self.mountedNode = mountedNode
    }

    private func appendToContainer(_ node: Node) {
        for handle in node.topLevelDOMHandles {
            backend.append(handle, to: container)
        }
    }
}
