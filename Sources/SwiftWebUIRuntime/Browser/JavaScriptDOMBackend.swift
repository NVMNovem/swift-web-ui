#if arch(wasm32)
import JavaScriptKit

final class JavaScriptDOMBackend: DOMBackend {
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

    func createElement(_ tagName: String) -> JSObject {
        document.createElement!(tagName).object!
    }

    func createTextNode(_ content: String) -> JSObject {
        document.createTextNode!(content).object!
    }

    func setText(_ content: String, on node: JSObject) {
        node.nodeValue = .string(content)
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
}
#endif
