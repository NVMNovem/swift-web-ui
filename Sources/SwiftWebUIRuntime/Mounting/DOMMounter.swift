@_spi(Rendering) import SwiftWebUI

struct DOMMounter<Backend: DOMBackend> {
    let backend: Backend

    func mount(_ node: WebNode) -> MountedNode<Backend.Node, Backend.ActionRegistration> {
        switch node {
        case .empty:
            return .empty
        case .text(let value):
            return .text(.init(handle: backend.createTextNode(value), value: value))
        case .fragment(let children):
            return .fragment(.init(children: children.map(mount)))
        case .element(let webElement):
            let handle = backend.createElement(webElement.tagName)
            for attribute in webElement.attributes {
                backend.setAttribute(name: attribute.name, value: attribute.value, on: handle)
            }
            for style in webElement.styles {
                backend.setStyle(name: style.name, value: style.value, on: handle)
            }
            let children = webElement.children.map(mount)
            for child in children.flatMap(\.topLevelDOMHandles) {
                backend.append(child, to: handle)
            }
            let registration = register(webElement.action, on: handle)
            return .element(.init(
                handle: handle,
                tagName: webElement.tagName,
                attributes: webElement.attributes,
                styles: webElement.styles,
                children: children,
                actionRegistration: registration
            ))
        }
    }

    func register(_ intent: ActionIntent?, on handle: Backend.Node) -> Backend.ActionRegistration? {
        guard case .closure(let action) = intent else { return nil }
        return backend.setClickAction(action, on: handle)
    }
}
