//
//  MountedRoot.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

@_spi(Runtime) @_spi(Rendering) import SwiftWebUI

final class MountedRoot<Backend: BrowserHeadBackend> {
    typealias Node = MountedNode<Backend.Node, Backend.ActionRegistration>

    private let container: Backend.Node
    private let build: () -> LoweredView
    private let backend: Backend
    private let differ = WebNodeDiffer()
    private let configuration: SwiftWebUIRuntimeConfiguration
    let installedResources: InstalledRuntimeResources<Backend.Node>
    private var previousWebNode: WebNode?
    private var mountedNode: Node?
    private let originalDocumentTitle: String
    private var appliedNavigationTitle: String?
    private var navigationIconHandle: Backend.Node?
    private var appliedNavigationIcon: NavigationIcon?

    /// Owns `@State` storage for everything mounted under this root.
    let stateSlots = StateSlotStore()
    /// Owns the document body's scroll lock for everything mounted under this root.
    ///
    /// Only the presentation primitive drives it. There is deliberately no
    /// public modifier for it — see ``ScrollLock``.
    let scrollLock: ScrollLock<Backend>
    /// Owns the frames and timers that enter and exit transitions run on.
    let transitions: TransitionScheduler<Backend>
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
        build: @escaping () -> LoweredView
    ) {
        self.container = container
        self.backend = backend
        self.configuration = configuration
        self.installedResources = installedResources
        self.build = build
        self.originalDocumentTitle = backend.documentTitle
        self.scrollLock = ScrollLock(backend: backend)
        self.transitions = TransitionScheduler(backend: backend)
    }

    convenience init(
        container: Backend.Node,
        backend: Backend,
        configuration: SwiftWebUIRuntimeConfiguration = .init(),
        installedResources: InstalledRuntimeResources<Backend.Node> = .init(),
        build: @escaping () -> WebNode
    ) {
        self.init(
            container: container,
            backend: backend,
            configuration: configuration,
            installedResources: installedResources,
            build: { LoweredView(webNode: build()) }
        )
    }

    func start() {
        StateSlotStorage.install(stateSlots)
        ViewInvalidation.install { [self] in
            invalidate()
        }
        initialMount()
    }

    func stop() {
        transitions.cancelAll()
        restoreDocumentTitle()
        removeNavigationIcon()
        ViewInvalidation.clear()
        StateSlotStorage.clear()
        stateSlots.releaseAll()
    }

    /// Rebuilds the presentation tree, reclaiming state for views that disappeared.
    private func buildTrackingState() -> LoweredView {
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
        let loweredView = buildTrackingState()
        let newWebNode = loweredView.webNode
        let patches = differ.diff(old: previousWebNode!, new: newWebNode)
        let applier = DOMPatchApplier(
            backend: backend,
            container: container,
            scrollLock: scrollLock,
            transitions: transitions,
            loggingEnabled: configuration.reconciliationLogging
        )
        do {
            try applier.apply(patches, to: &mountedNode)
            self.mountedNode = mountedNode
        } catch {
            print("[SwiftWebUIRuntime] reconciliation fallback: \(error)")
            applier.recursivelyReleaseActions(in: mountedNode)
            transitions.cancelAll()
            backend.removeAllChildren(from: container)
            let mounter = DOMMounter(backend: backend, scrollLock: scrollLock, transitions: transitions)
            var pending = DOMMounter<Backend>.PendingInsertionEffects()
            let replacement = mounter.mount(newWebNode, pending: &pending)
            appendToContainer(replacement)
            mounter.flush(pending)
            self.mountedNode = replacement
        }
        previousWebNode = newWebNode
        applyNavigationTitle(loweredView.documentMetadata.navigationTitle)
        applyNavigationIcon(loweredView.documentMetadata.navigationIcon)
    }

    private func initialMount() {
        if let mountedNode {
            DOMPatchApplier(
                backend: backend,
                container: container,
                scrollLock: scrollLock,
                transitions: transitions
            ).recursivelyReleaseActions(in: mountedNode)
        }
        // Nothing that was waiting to leave has a parent any more.
        transitions.cancelAll()
        backend.removeAllChildren(from: container)
        let loweredView = buildTrackingState()
        let webNode = loweredView.webNode
        let mounter = DOMMounter(backend: backend, scrollLock: scrollLock, transitions: transitions)
        var pending = DOMMounter<Backend>.PendingInsertionEffects()
        let mountedNode = mounter.mount(webNode, pending: &pending)
        appendToContainer(mountedNode)
        mounter.flush(pending)
        previousWebNode = webNode
        self.mountedNode = mountedNode
        applyNavigationTitle(loweredView.documentMetadata.navigationTitle)
        applyNavigationIcon(loweredView.documentMetadata.navigationIcon)
    }

    private func applyNavigationTitle(_ title: String?) {
        guard title != appliedNavigationTitle else { return }
        backend.setDocumentTitle(title ?? originalDocumentTitle)
        appliedNavigationTitle = title
    }

    private func restoreDocumentTitle() {
        guard appliedNavigationTitle != nil else { return }
        backend.setDocumentTitle(originalDocumentTitle)
        appliedNavigationTitle = nil
    }

    private func applyNavigationIcon(_ icon: NavigationIcon?) {
        guard icon != appliedNavigationIcon else { return }
        guard let icon else {
            removeNavigationIcon()
            return
        }

        do {
            let head = try backend.documentHead()
            let handle: Backend.Node
            if let navigationIconHandle {
                handle = navigationIconHandle
            } else {
                handle = backend.createElement("link")
                backend.setAttribute(name: "rel", value: "icon", on: handle)
                backend.append(handle, to: head)
                navigationIconHandle = handle
            }

            backend.setAttribute(name: "href", value: icon.href, on: handle)
            if let mimeType = icon.mimeType {
                backend.setAttribute(name: "type", value: mimeType, on: handle)
            } else {
                backend.removeAttribute(name: "type", from: handle)
            }
            appliedNavigationIcon = icon
        } catch {
            print("[SwiftWebUIRuntime] navigation icon installation failed: \(error)")
        }
    }

    private func removeNavigationIcon() {
        guard let navigationIconHandle else { return }
        do {
            let head = try backend.documentHead()
            backend.remove(navigationIconHandle, from: head)
            self.navigationIconHandle = nil
            appliedNavigationIcon = nil
        } catch {
            print("[SwiftWebUIRuntime] navigation icon removal failed: \(error)")
        }
    }

    private func appendToContainer(_ node: Node) {
        for handle in node.topLevelDOMHandles {
            backend.append(handle, to: container)
        }
    }
}
