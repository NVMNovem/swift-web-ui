//
//  DOMMounter.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

@_spi(Rendering) import SwiftWebUI

struct DOMMounter<Backend: BrowserHeadBackend> {
    typealias Node = MountedNode<Backend.Node, Backend.ActionRegistration>
    typealias Element = MountedElementNode<Backend.Node, Backend.ActionRegistration>

    /// Work a freshly mounted subtree cannot do until it is in the document.
    ///
    /// `focus()` on a detached node is silently a no-op, and `showModal()` on one
    /// throws. The mounter cannot insert its own handle — its caller does that —
    /// so it collects both here and the caller flushes them afterwards.
    struct PendingInsertionEffects {
        var focusRequests: [Backend.Node] = []
        var presentations: [(element: Element, presentation: DialogPresentation)] = []

        var isEmpty: Bool { focusRequests.isEmpty && presentations.isEmpty }
    }

    let backend: Backend
    let scrollLock: ScrollLock<Backend>

    func mount(_ node: WebNode, pending: inout PendingInsertionEffects) -> Node {
        switch node {
        case .empty:
            return .empty
        case .text(let value):
            return .text(.init(handle: backend.createTextNode(value), value: value))
        case .fragment(let children):
            var mountedChildren: [Node] = []
            mountedChildren.reserveCapacity(children.count)
            for child in children {
                mountedChildren.append(mount(child, pending: &pending))
            }
            return .fragment(.init(children: mountedChildren))
        case .element(let webElement):
            let handle = backend.createElement(webElement.tagName)
            for attribute in webElement.attributes {
                backend.setAttribute(name: attribute.name, value: attribute.value, on: handle)
            }
            for style in webElement.styles {
                backend.setStyle(name: style.name, value: style.value, on: handle)
            }
            var children: [Node] = []
            children.reserveCapacity(webElement.children.count)
            for child in webElement.children {
                children.append(mount(child, pending: &pending))
            }
            for child in children.flatMap(\.topLevelDOMHandles) {
                backend.append(child, to: handle)
            }
            let element = Element(
                handle: handle,
                tagName: webElement.tagName,
                attributes: webElement.attributes,
                styles: webElement.styles,
                children: children,
                actionRegistration: register(webElement.action, on: handle),
                keyActionRegistrations: registerKeyActions(webElement.keyActions, on: handle),
                dismissRegistration: registerDismissAction(webElement.dismissAction, on: handle)
            )
            if webElement.requestsFocus {
                pending.focusRequests.append(handle)
            }
            if let presentation = webElement.presentation, presentation.isPresented {
                pending.presentations.append((element, presentation))
            }
            return .element(element)
        }
    }

    /// Performs everything ``mount(_:pending:)`` deferred.
    ///
    /// Call this only after the mounted handles are in the document.
    func flush(_ pending: PendingInsertionEffects) {
        for (element, presentation) in pending.presentations {
            present(presentation, on: element)
        }
        for handle in pending.focusRequests {
            backend.focus(handle)
        }
    }

    /// Presents an element that is already in the document, taking the scroll
    /// lock for a modal one.
    func present(_ presentation: DialogPresentation, on element: Element) {
        guard presentation.isPresented else {
            dismiss(element)
            return
        }
        backend.presentDialog(element.handle, modal: presentation == .modal)
        element.presentation = presentation
        if presentation == .modal, !element.holdsScrollLock {
            scrollLock.acquire()
            element.holdsScrollLock = true
        } else if presentation != .modal, element.holdsScrollLock {
            scrollLock.release()
            element.holdsScrollLock = false
        }
    }

    /// Dismisses an element, releasing the scroll lock if it held one.
    func dismiss(_ element: Element) {
        if element.presentation?.isPresented == true {
            backend.dismissDialog(element.handle)
        }
        element.presentation = .dismissed
        releaseScrollLock(of: element)
    }

    /// Releases an element's hold on the scroll lock, exactly once.
    func releaseScrollLock(of element: Element) {
        guard element.holdsScrollLock else { return }
        scrollLock.release()
        element.holdsScrollLock = false
    }

    func register(_ intent: ActionIntent?, on handle: Backend.Node) -> Backend.ActionRegistration? {
        guard case .closure(let action) = intent else { return nil }
        return backend.setClickAction(action, on: handle)
    }

    func registerDismissAction(
        _ intent: ActionIntent?,
        on handle: Backend.Node
    ) -> Backend.ActionRegistration? {
        guard case .closure(let action) = intent else { return nil }
        return backend.setDismissAction(action, on: handle)
    }

    /// Installs every key-down handler for one element.
    ///
    /// Key actions are filtered to closures for the same reason click actions
    /// are: a `setState` intent is a static-resource feature with no runtime
    /// registration behind it.
    func registerKeyActions(
        _ keyActions: [KeyAction],
        on handle: Backend.Node
    ) -> [Backend.ActionRegistration] {
        var closures: [String: () -> Void] = [:]
        var keys: [String] = []
        for keyAction in keyActions {
            guard case .closure(let action) = keyAction.action else { continue }
            if closures.updateValue(action, forKey: keyAction.key) == nil {
                keys.append(keyAction.key)
            }
        }
        guard !keys.isEmpty else { return [] }
        return [backend.setKeyAction(keys: keys, action: { closures[$0]?() }, on: handle)]
    }
}
