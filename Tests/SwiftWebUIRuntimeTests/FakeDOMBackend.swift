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
    var children: [FakeDOMNode] = []

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

    private var nextNodeID = 1
    private var nextRegistration = 1
    let root = FakeDOMNode(id: 0, tagName: "root")
    let head = FakeDOMNode(id: -1, tagName: "head")
    var operations: [String] = []
    var releasedRegistrations: [Int] = []
    var buildCount = 0
    var failResourceTextInstallation = false

    func documentHead() throws -> FakeDOMNode {
        operations.append("documentHead")
        return head
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
}

func mounted(
    _ webNode: WebNode,
    backend: FakeDOMBackend
) -> MountedNode<FakeDOMNode, Int> {
    let result = DOMMounter(backend: backend).mount(webNode)
    for handle in result.topLevelDOMHandles {
        backend.append(handle, to: backend.root)
    }
    return result
}

func element(
    _ tag: String = "div",
    attributes: [WebAttribute] = [],
    styles: [WebStyleDeclaration] = [],
    children: [WebNode] = [],
    action: ActionIntent? = nil
) -> WebNode {
    .element(.init(
        tagName: tag,
        attributes: attributes,
        styles: styles,
        children: children,
        action: action
    ))
}
