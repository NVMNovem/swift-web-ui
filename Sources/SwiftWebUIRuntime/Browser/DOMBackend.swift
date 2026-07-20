//
//  DOMBackend.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

protocol DOMBackend: AnyObject {
    associatedtype Node
    associatedtype ActionRegistration

    func createElement(_ tagName: String) -> Node
    func createTextNode(_ content: String) -> Node
    func setText(_ content: String, on node: Node)
    func setAttribute(name: String, value: String, on node: Node)
    func removeAttribute(name: String, from node: Node)
    func setStyle(name: String, value: String, on node: Node)
    func removeStyle(name: String, from node: Node)
    func setClickAction(_ action: @escaping () -> Void, on node: Node) -> ActionRegistration
    func removeClickAction(from node: Node, registration: ActionRegistration)
    func append(_ child: Node, to parent: Node)
    func insert(_ child: Node, into parent: Node, before reference: Node?)
    func remove(_ child: Node, from parent: Node)
    func removeAllChildren(from parent: Node)
}
