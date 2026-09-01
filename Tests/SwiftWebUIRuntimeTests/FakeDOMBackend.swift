//
//  FakeDOMBackend.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

@_spi(Rendering) import SwiftWebUI
@testable import SwiftWebUIRuntime

final class FakeDOMNode {
    let id: Int
    let tagName: String?
    var text: String?
    var attributes: [String: String] = [:]
    var styles: [String: String] = [:]
    var action: (() -> Void)?
    var keyAction: ((String) -> Void)?
    var keyActionKeys: [String] = []
    var dismissAction: (() -> Void)?
    var isPresented = false
    var isModal = false
    var children: [FakeDOMNode] = []

    /// Closes the dialog the way the browser would, notifying the page after.
    func browserDismiss() {
        guard isPresented else { return }
        isPresented = false
        isModal = false
        dismissAction?()
    }

    /// Delivers a key-down the way the browser would: only for a claimed key.
    func pressKey(_ key: String) {
        guard keyActionKeys.contains(key) else { return }
        keyAction?(key)
    }

    init(id: Int, tagName: String? = nil, text: String? = nil) {
        self.id = id
        self.tagName = tagName
        self.text = text
    }
}

enum FakeDOMBackendError: Error {
    case resourceInstallationFailed
}

final class FakeDOMBackend: BrowserHeadBackend {
    typealias Node = FakeDOMNode
    typealias ActionRegistration = Int

    /// A piece of scheduled work the test drives by hand.
    final class ScheduledWork {
        let body: () -> Void
        let milliseconds: Int?
        var isCancelled = false

        init(body: @escaping () -> Void, milliseconds: Int?) {
            self.body = body
            self.milliseconds = milliseconds
        }
    }

    private var nextNodeID = 1
    private var nextRegistration = 1
    let root = FakeDOMNode(id: 0, tagName: "root")
    let head = FakeDOMNode(id: -1, tagName: "head")
    let body = FakeDOMNode(id: -2, tagName: "body")
    var failDocumentBody = false
    var operations: [String] = []
    var releasedRegistrations: [Int] = []
    var focusedNodes: [FakeDOMNode] = []
    var buildCount = 0
    var failResourceTextInstallation = false
    var documentTitle = "Host Document"

    func setDocumentTitle(_ title: String) {
        operations.append("setDocumentTitle \(title)")
        documentTitle = title
    }

    func documentHead() throws -> FakeDOMNode {
        operations.append("documentHead")
        return head
    }

    func documentBody() throws -> FakeDOMNode {
        operations.append("documentBody")
        if failDocumentBody {
            throw BrowserHeadBackendError.documentBodyUnavailable
        }
        return body
    }

    func inlineStyleValue(name: String, on node: FakeDOMNode) -> String? {
        node.styles[name]
    }

    func createElement(_ tagName: String) -> FakeDOMNode {
        defer { nextNodeID += 1 }
        operations.append("createElement \(tagName)")
        return FakeDOMNode(id: nextNodeID, tagName: tagName)
    }

    func createTextNode(_ content: String) -> FakeDOMNode {
        defer { nextNodeID += 1 }
        operations.append("createText \(content)")
        return FakeDOMNode(id: nextNodeID, text: content)
    }

    func setText(_ content: String, on node: FakeDOMNode) {
        operations.append("setText \(node.id) \(content)")
        node.text = content
    }

    func setResourceText(_ content: String, on node: FakeDOMNode) throws {
        if failResourceTextInstallation {
            throw FakeDOMBackendError.resourceInstallationFailed
        }
        operations.append("setResourceText \(node.id) \(content)")
        node.text = content
    }

    func setAttribute(name: String, value: String, on node: FakeDOMNode) {
        operations.append("setAttribute \(node.id) \(name)=\(value)")
        node.attributes[name] = value
    }

    func removeAttribute(name: String, from node: FakeDOMNode) {
        operations.append("removeAttribute \(node.id) \(name)")
        node.attributes[name] = nil
    }

    func setStyle(name: String, value: String, on node: FakeDOMNode) {
        operations.append("setStyle \(node.id) \(name)=\(value)")
        node.styles[name] = value
    }

    func removeStyle(name: String, from node: FakeDOMNode) {
        operations.append("removeStyle \(node.id) \(name)")
        node.styles[name] = nil
    }

    func setClickAction(_ action: @escaping () -> Void, on node: FakeDOMNode) -> Int {
        defer { nextRegistration += 1 }
        operations.append("setAction \(node.id) \(nextRegistration)")
        node.action = action
        return nextRegistration
    }

    func removeClickAction(from node: FakeDOMNode, registration: Int) {
        operations.append("removeAction \(node.id) \(registration)")
        releasedRegistrations.append(registration)
        node.action = nil
    }

    func setKeyAction(
        keys: [String],
        action: @escaping (String) -> Void,
        on node: FakeDOMNode
    ) -> Int {
        defer { nextRegistration += 1 }
        operations.append("setKeyAction \(node.id) \(nextRegistration) [\(keys.joined(separator: ", "))]")
        node.keyAction = action
        node.keyActionKeys = keys
        return nextRegistration
    }

    func removeKeyAction(from node: FakeDOMNode, registration: Int) {
        operations.append("removeKeyAction \(node.id) \(registration)")
        releasedRegistrations.append(registration)
        node.keyAction = nil
        node.keyActionKeys = []
    }

    func presentDialog(_ node: FakeDOMNode, modal: Bool) {
        operations.append("presentDialog \(node.id) modal=\(modal)")
        node.isPresented = true
        node.isModal = modal
    }

    func dismissDialog(_ node: FakeDOMNode) {
        operations.append("dismissDialog \(node.id)")
        node.isPresented = false
        node.isModal = false
    }

    func setDismissAction(_ action: @escaping () -> Void, on node: FakeDOMNode) -> Int {
        defer { nextRegistration += 1 }
        operations.append("setDismissAction \(node.id) \(nextRegistration)")
        node.dismissAction = action
        return nextRegistration
    }

    func removeDismissAction(from node: FakeDOMNode, registration: Int) {
        operations.append("removeDismissAction \(node.id) \(registration)")
        releasedRegistrations.append(registration)
        node.dismissAction = nil
    }

    func append(_ child: FakeDOMNode, to parent: FakeDOMNode) {
        operations.append("append \(child.id) to \(parent.id)")
        parent.children.append(child)
    }

    func insert(_ child: FakeDOMNode, into parent: FakeDOMNode, before reference: FakeDOMNode?) {
        operations.append("insert \(child.id) into \(parent.id) before \(reference?.id.description ?? "nil")")
        if let reference, let index = parent.children.firstIndex(where: { $0 === reference }) {
            parent.children.insert(child, at: index)
        } else {
            parent.children.append(child)
        }
    }

    func remove(_ child: FakeDOMNode, from parent: FakeDOMNode) {
        operations.append("remove \(child.id) from \(parent.id)")
        parent.children.removeAll { $0 === child }
    }

    func removeAllChildren(from parent: FakeDOMNode) {
        operations.append("removeAll \(parent.id)")
        parent.children.removeAll()
    }

    var reducedMotion = false
    private(set) var scheduled: [ScheduledWork] = []
    private(set) var cancelledWork = 0

    func onNextAnimationFrame(_ body: @escaping () -> Void) -> ScheduledWork {
        operations.append("requestAnimationFrame")
        let work = ScheduledWork(body: body, milliseconds: nil)
        scheduled.append(work)
        return work
    }

    func schedule(afterMilliseconds milliseconds: Int, _ body: @escaping () -> Void) -> ScheduledWork {
        operations.append("setTimeout \(milliseconds)")
        let work = ScheduledWork(body: body, milliseconds: milliseconds)
        scheduled.append(work)
        return work
    }

    func cancel(_ work: ScheduledWork) {
        operations.append("cancelScheduled")
        work.isCancelled = true
        cancelledWork += 1
    }

    func prefersReducedMotion() -> Bool { reducedMotion }

    /// Runs everything the browser would have run, in the order it was queued.
    func runScheduledWork() {
        let due = scheduled
        scheduled.removeAll()
        for work in due where !work.isCancelled {
            work.body()
        }
    }

    func focus(_ node: FakeDOMNode) {
        operations.append("focus \(node.id)")
        focusedNodes.append(node)
    }
}

func mounted(
    _ webNode: WebNode,
    backend: FakeDOMBackend,
    scrollLock: ScrollLock<FakeDOMBackend>? = nil,
    transitions: TransitionScheduler<FakeDOMBackend>? = nil
) -> MountedNode<FakeDOMNode, Int> {
    let mounter = DOMMounter(
        backend: backend,
        scrollLock: scrollLock ?? ScrollLock(backend: backend),
        transitions: transitions ?? TransitionScheduler(backend: backend)
    )
    var pending = DOMMounter<FakeDOMBackend>.PendingInsertionEffects()
    let result = mounter.mount(webNode, pending: &pending)
    for handle in result.topLevelDOMHandles {
        backend.append(handle, to: backend.root)
    }
    mounter.flush(pending)
    return result
}

func element(
    _ tag: String = "div",
    attributes: [WebAttribute] = [],
    styles: [WebStyleDeclaration] = [],
    children: [WebNode] = [],
    action: ActionIntent? = nil,
    requestsFocus: Bool = false,
    keyActions: [KeyAction] = [],
    presentation: DialogPresentation? = nil,
    dismissAction: ActionIntent? = nil,
    transitionPhases: TransitionPhases? = nil
) -> WebNode {
    .element(.init(
        tagName: tag,
        attributes: attributes,
        styles: styles,
        children: children,
        action: action,
        requestsFocus: requestsFocus,
        keyActions: keyActions,
        presentation: presentation,
        dismissAction: dismissAction,
        transitionPhases: transitionPhases
    ))
}
