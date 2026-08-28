//
//  JavaScriptDOMBackend.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

#if arch(wasm32)
import JavaScriptKit

final class JavaScriptDOMBackend: BrowserHeadBackend {
    typealias Node = JSObject
    typealias ActionRegistration = JSClosure

    private let document: JSObject

    init?() {
        guard let document = JSObject.global.document.object else {
            return nil
        }
        self.document = document
    }

    func element(withID identifier: String) -> JSObject? {
        document.getElementById!(identifier).object
    }

    func documentHead() throws -> JSObject {
        guard let head = document.head.object else {
            throw BrowserHeadBackendError.documentHeadUnavailable
        }
        return head
    }

    func documentBody() throws -> JSObject {
        guard let body = document.body.object else {
            throw BrowserHeadBackendError.documentBodyUnavailable
        }
        return body
    }

    func inlineStyleValue(name: String, on node: JSObject) -> String? {
        guard let value = node.style.object?.getPropertyValue!(name).string, !value.isEmpty else {
            return nil
        }
        return value
    }

    func createElement(_ tagName: String) -> JSObject {
        document.createElement!(tagName).object!
    }

    func createTextNode(_ content: String) -> JSObject {
        document.createTextNode!(content).object!
    }

    func setText(_ content: String, on node: JSObject) {
        node.nodeValue = .string(content)
    }

    func setResourceText(_ content: String, on node: JSObject) throws {
        node.textContent = .string(content)
    }

    func setAttribute(name: String, value: String, on node: JSObject) {
        _ = node.setAttribute!(name, value)
    }

    func removeAttribute(name: String, from node: JSObject) {
        _ = node.removeAttribute!(name)
    }

    func setStyle(name: String, value: String, on node: JSObject) {
        _ = node.style.object!.setProperty!(name, value)
    }

    func removeStyle(name: String, from node: JSObject) {
        _ = node.style.object!.removeProperty!(name)
    }

    func setClickAction(_ action: @escaping () -> Void, on node: JSObject) -> JSClosure {
        let handler = JSClosure { _ in
            action()
            return .undefined
        }
        node.onclick = .object(handler)
        return handler
    }

    func removeClickAction(from node: JSObject, registration: JSClosure) {
        node.onclick = .null
    }

    func setKeyAction(
        keys: [String],
        action: @escaping (String) -> Void,
        on node: JSObject
    ) -> JSClosure {
        let handler = JSClosure { arguments in
            guard let key = arguments.first?.key.string, keys.contains(key) else {
                return .undefined
            }
            action(key)
            return .undefined
        }
        node.onkeydown = .object(handler)
        return handler
    }

    func removeKeyAction(from node: JSObject, registration: JSClosure) {
        node.onkeydown = .null
    }

    func presentDialog(_ node: JSObject, modal: Bool) {
        if modal {
            _ = node.showModal!()
        } else {
            _ = node.show!()
        }
    }

    func dismissDialog(_ node: JSObject) {
        _ = node.close!()
    }

    func setDismissAction(_ action: @escaping () -> Void, on node: JSObject) -> JSClosure {
        let handler = JSClosure { _ in
            action()
            return .undefined
        }
        // `close` rather than `cancel`: Escape, the backdrop, and an explicit
        // `close()` all end in `close`, and only `cancel` is preventable.
        node.onclose = .object(handler)
        return handler
    }

    func removeDismissAction(from node: JSObject, registration: JSClosure) {
        node.onclose = .null
    }

    func append(_ child: JSObject, to parent: JSObject) {
        _ = parent.appendChild!(child)
    }

    func insert(_ child: JSObject, into parent: JSObject, before reference: JSObject?) {
        if let reference {
            _ = parent.insertBefore!(child, reference)
        } else {
            _ = parent.appendChild!(child)
        }
    }

    func remove(_ child: JSObject, from parent: JSObject) {
        _ = parent.removeChild!(child)
    }

    func removeAllChildren(from parent: JSObject) {
        _ = parent.replaceChildren!()
    }

    func focus(_ node: JSObject) {
        _ = node.focus!()
    }
}
#endif
