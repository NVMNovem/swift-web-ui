//
//  DOMPatchApplier.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

@_spi(Rendering) import SwiftWebUI

enum DOMPatchApplicationError: Error, CustomStringConvertible {
    case invalidPath(NodePath)
    case expectedText(NodePath)
    case expectedElement(NodePath)
    case expectedContainer(NodePath)

    var description: String {
        switch self {
        case .invalidPath(let path): "invalid mounted path \(path.indices)"
        case .expectedText(let path): "expected mounted text at \(path.indices)"
        case .expectedElement(let path): "expected mounted element at \(path.indices)"
        case .expectedContainer(let path): "expected mounted container at \(path.indices)"
        }
    }
}

final class DOMPatchApplier<Backend: BrowserHeadBackend> {
    typealias Node = MountedNode<Backend.Node, Backend.ActionRegistration>

    private let backend: Backend
    private let container: Backend.Node
    private let scrollLock: ScrollLock<Backend>
    private let transitions: TransitionScheduler<Backend>
    private let loggingEnabled: Bool

    init(
        backend: Backend,
        container: Backend.Node,
        scrollLock: ScrollLock<Backend>,
        transitions: TransitionScheduler<Backend>,
        loggingEnabled: Bool = false
    ) {
        self.backend = backend
        self.container = container
        self.scrollLock = scrollLock
        self.transitions = transitions
        self.loggingEnabled = loggingEnabled
    }

    private var mounter: DOMMounter<Backend> {
        DOMMounter(backend: backend, scrollLock: scrollLock, transitions: transitions)
    }

    func apply(_ patches: [DOMPatch], to mountedRoot: inout Node) throws {
        for patch in patches {
            if loggingEnabled {
                print("[SwiftWebUIRuntime] \(patch)")
            }
            try apply(patch, to: &mountedRoot)
        }
    }

    func recursivelyReleaseActions(in node: Node) {
        switch node {
        case .empty, .text:
            break
        case .element(let element):
            for child in element.children {
                recursivelyReleaseActions(in: child)
            }
            if let registration = element.actionRegistration {
                backend.removeClickAction(from: element.handle, registration: registration)
                element.actionRegistration = nil
            }
            releaseKeyActions(of: element)
            if let registration = element.dismissRegistration {
                backend.removeDismissAction(from: element.handle, registration: registration)
                element.dismissRegistration = nil
            }
            // A presented dialog that goes away must give the scroll lock back,
            // or the page can never scroll again.
            mounter.releaseScrollLock(of: element)
        case .fragment(let fragment):
            for child in fragment.children {
                recursivelyReleaseActions(in: child)
            }
        }
    }

    private func apply(_ patch: DOMPatch, to mountedRoot: inout Node) throws {
        switch patch {
        case .setText(let path, let value):
            guard case .text(let text) = try node(at: path, in: mountedRoot) else {
                throw DOMPatchApplicationError.expectedText(path)
            }
            backend.setText(value, on: text.handle)
            text.value = value
        case .setAttribute(let path, let name, let value):
            let element = try element(at: path, in: mountedRoot)
            setNamedValue(name: name, value: value, in: &element.attributes)
            if name == "class" {
                // Rewriting `class` outright would drop a phase mid-transition.
                mounter.writeClassAttribute(of: element)
            } else {
                backend.setAttribute(name: name, value: value, on: element.handle)
            }
        case .removeAttribute(let path, let name):
            let element = try element(at: path, in: mountedRoot)
            element.attributes.removeAll { $0.name == name }
            if name == "class" {
                mounter.writeClassAttribute(of: element)
            } else {
                backend.removeAttribute(name: name, from: element.handle)
            }
        case .setStyle(let path, let name, let value):
            let element = try element(at: path, in: mountedRoot)
            backend.setStyle(name: name, value: value, on: element.handle)
            setNamedValue(name: name, value: value, in: &element.styles)
        case .removeStyle(let path, let name):
            let element = try element(at: path, in: mountedRoot)
            backend.removeStyle(name: name, from: element.handle)
            element.styles.removeAll { $0.name == name }
        case .replaceAction(let path, let action):
            let element = try element(at: path, in: mountedRoot)
            if let registration = element.actionRegistration {
                backend.removeClickAction(from: element.handle, registration: registration)
            }
            element.actionRegistration = mounter.register(action, on: element.handle)
        case .replaceKeyActions(let path, let actions):
            let element = try element(at: path, in: mountedRoot)
            releaseKeyActions(of: element)
            element.keyActionRegistrations = mounter.registerKeyActions(actions, on: element.handle)
        case .replaceDismissAction(let path, let action):
            let element = try element(at: path, in: mountedRoot)
            if let registration = element.dismissRegistration {
                backend.removeDismissAction(from: element.handle, registration: registration)
            }
            element.dismissRegistration = mounter.registerDismissAction(action, on: element.handle)
        case .setDialogPresentation(let path, let presentation):
            let element = try element(at: path, in: mountedRoot)
            mounter.present(presentation, on: element)
        case .setTransitionPhases(let path, let phases):
            try element(at: path, in: mountedRoot).transitionPhases = phases
        case .insertChild(let parentPath, let index, let webNode):
            try insertChild(webNode, at: index, parentPath: parentPath, root: mountedRoot)
        case .removeChild(let parentPath, let index):
            try removeChild(at: index, parentPath: parentPath, root: mountedRoot)
        case .replaceNode(let path, let webNode):
            try replaceNode(at: path, with: webNode, root: &mountedRoot)
        case .focus(let path):
            let element = try element(at: path, in: mountedRoot)
            backend.focus(element.handle)
        }
    }

    /// Frees every key-down registration an element holds.
    ///
    /// An unreleased handler leaks on every rebuild, which is what
    /// ``recursivelyReleaseActions(in:)`` exists to prevent.
    private func releaseKeyActions(of element: MountedElementNode<Backend.Node, Backend.ActionRegistration>) {
        for registration in element.keyActionRegistrations {
            backend.removeKeyAction(from: element.handle, registration: registration)
        }
        element.keyActionRegistrations = []
    }

    private func insertChild(_ webNode: WebNode, at index: Int, parentPath: NodePath, root: Node) throws {
        var context = try context(at: parentPath, in: root)
        guard isContainer(context.node) else {
            throw DOMPatchApplicationError.expectedContainer(parentPath)
        }
        let domParent = childDOMParent(for: context.node, inherited: context.domParent)
        var children = context.node.children
        guard index >= 0, index <= children.count else {
            throw DOMPatchApplicationError.invalidPath(parentPath.appending(index))
        }
        let reference = children[index...].lazy.compactMap(\.firstDOMHandle).first
        let mounter = mounter
        var pending = DOMMounter<Backend>.PendingInsertionEffects()
        let mounted = mounter.mount(webNode, pending: &pending)
        for handle in mounted.topLevelDOMHandles {
            backend.insert(handle, into: domParent, before: reference)
        }
        mounter.flush(pending)
        children.insert(mounted, at: index)
        context.node.children = children
    }

    private func removeChild(at index: Int, parentPath: NodePath, root: Node) throws {
        var context = try context(at: parentPath, in: root)
        guard isContainer(context.node) else {
            throw DOMPatchApplicationError.expectedContainer(parentPath)
        }
        let domParent = childDOMParent(for: context.node, inherited: context.domParent)
        var children = context.node.children
        guard children.indices.contains(index) else {
            throw DOMPatchApplicationError.invalidPath(parentPath.appending(index))
        }
        let removed = children.remove(at: index)
        recursivelyReleaseActions(in: removed)
        // The mounted tree drops the child now, so every later sibling keeps the
        // index it already had and every subsequent patch in this batch still
        // resolves to the element it meant. A leaving element outlives that only
        // in the DOM, where nothing addresses it positionally.
        context.node.children = children
        beginExit(of: removed, from: domParent)
    }

    /// Removes a leaving subtree, letting it run an exit transition first.
    ///
    /// The element is already out of the mounted tree, so nothing can address it
    /// by path any more and nothing will re-insert this handle — a later render
    /// mounts a new one. That is what makes holding it in the DOM safe.
    private func beginExit(of removed: Node, from domParent: Backend.Node) {
        let handles = removed.topLevelDOMHandles
        guard
            case .element(let element) = removed,
            let phases = element.transitionPhases
        else {
            for handle in handles { backend.remove(handle, from: domParent) }
            return
        }
        mounter.setPhaseClass(phases.exit, on: element)
        transitions.after(milliseconds: phases.durationMilliseconds) { [backend] in
            for handle in handles { backend.remove(handle, from: domParent) }
        }
    }

    private func replaceNode(at path: NodePath, with webNode: WebNode, root: inout Node) throws {
        let context = try context(at: path, in: root)
        let mounter = mounter
        var pending = DOMMounter<Backend>.PendingInsertionEffects()
        let replacement = mounter.mount(webNode, pending: &pending)
        let reference = context.node.firstDOMHandle ?? nextDOMHandle(after: path, in: root)
        for handle in replacement.topLevelDOMHandles {
            backend.insert(handle, into: context.domParent, before: reference)
        }
        mounter.flush(pending)
        recursivelyReleaseActions(in: context.node)
        for handle in context.node.topLevelDOMHandles {
            backend.remove(handle, from: context.domParent)
        }

        guard let lastIndex = path.indices.last else {
            root = replacement
            return
        }
        let parentPath = NodePath(Array(path.indices.dropLast()))
        var parent = try node(at: parentPath, in: root)
        var children = parent.children
        guard children.indices.contains(lastIndex) else {
            throw DOMPatchApplicationError.invalidPath(path)
        }
        children[lastIndex] = replacement
        parent.children = children
    }

    private func nextDOMHandle(after path: NodePath, in root: Node) -> Backend.Node? {
        var candidate = path
        while let index = candidate.indices.last {
            let parentPath = NodePath(Array(candidate.indices.dropLast()))
            guard let parent = try? node(at: parentPath, in: root) else { return nil }
            let siblings = parent.children
            if index + 1 < siblings.count,
               let handle = siblings[(index + 1)...].lazy.compactMap(\.firstDOMHandle).first {
                return handle
            }
            if case .element = parent {
                return nil
            }
            candidate = parentPath
        }
        return nil
    }

    private func setNamedValue(name: String, value: String, in values: inout [WebAttribute]) {
        if let index = values.firstIndex(where: { $0.name == name }) {
            values[index] = .init(name: name, value: value)
        } else {
            values.append(.init(name: name, value: value))
        }
    }

    private func setNamedValue(name: String, value: String, in values: inout [WebStyleDeclaration]) {
        if let index = values.firstIndex(where: { $0.name == name }) {
            values[index] = .init(name: name, value: value)
        } else {
            values.append(.init(name: name, value: value))
        }
    }

    private func element(at path: NodePath, in root: Node) throws -> MountedElementNode<Backend.Node, Backend.ActionRegistration> {
        guard case .element(let element) = try node(at: path, in: root) else {
            throw DOMPatchApplicationError.expectedElement(path)
        }
        return element
    }

    private func node(at path: NodePath, in root: Node) throws -> Node {
        try context(at: path, in: root).node
    }

    private func context(at path: NodePath, in root: Node) throws -> (node: Node, domParent: Backend.Node) {
        var current = root
        var domParent = container
        var traversed: [Int] = []
        for index in path.indices {
            if case .element(let element) = current {
                domParent = element.handle
            }
            let children = current.children
            traversed.append(index)
            guard children.indices.contains(index) else {
                throw DOMPatchApplicationError.invalidPath(NodePath(traversed))
            }
            current = children[index]
        }
        return (current, domParent)
    }

    private func childDOMParent(for node: Node, inherited: Backend.Node) -> Backend.Node {
        if case .element(let element) = node {
            return element.handle
        }
        return inherited
    }

    private func isContainer(_ node: Node) -> Bool {
        switch node {
        case .element, .fragment: true
        case .empty, .text: false
        }
    }
}
