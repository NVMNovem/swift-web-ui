//
//  DOMPatch.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

@_spi(Rendering) import SwiftWebUI

enum DOMPatch: @unchecked Sendable, Equatable {
    case setText(path: NodePath, value: String)
    case setAttribute(path: NodePath, name: String, value: String)
    case removeAttribute(path: NodePath, name: String)
    case setStyle(path: NodePath, name: String, value: String)
    case removeStyle(path: NodePath, name: String)
    case insertChild(parent: NodePath, index: Int, node: WebNode)
    case removeChild(parent: NodePath, index: Int)
    case replaceNode(path: NodePath, node: WebNode)
    case replaceAction(path: NodePath, action: ActionIntent?)
}

extension DOMPatch {
    static func == (lhs: DOMPatch, rhs: DOMPatch) -> Bool {
        switch (lhs, rhs) {
        case (.setText(let lp, let lv), .setText(let rp, let rv)):
            lp == rp && lv == rv
        case (.setAttribute(let lp, let ln, let lv), .setAttribute(let rp, let rn, let rv)):
            lp == rp && ln == rn && lv == rv
        case (.removeAttribute(let lp, let ln), .removeAttribute(let rp, let rn)):
            lp == rp && ln == rn
        case (.setStyle(let lp, let ln, let lv), .setStyle(let rp, let rn, let rv)):
            lp == rp && ln == rn && lv == rv
        case (.removeStyle(let lp, let ln), .removeStyle(let rp, let rn)):
            lp == rp && ln == rn
        case (.insertChild(let lp, let li, let ln), .insertChild(let rp, let ri, let rn)):
            lp == rp && li == ri && webNodesEqual(ln, rn)
        case (.removeChild(let lp, let li), .removeChild(let rp, let ri)):
            lp == rp && li == ri
        case (.replaceNode(let lp, let ln), .replaceNode(let rp, let rn)):
            lp == rp && webNodesEqual(ln, rn)
        case (.replaceAction(let lp, let la), .replaceAction(let rp, let ra)):
            lp == rp && actionsEquivalent(la, ra)
        default:
            false
        }
    }
}

private func webNodesEqual(_ lhs: WebNode, _ rhs: WebNode) -> Bool {
    switch (lhs, rhs) {
    case (.empty, .empty): true
    case (.text(let lhs), .text(let rhs)): lhs == rhs
    case (.fragment(let lhs), .fragment(let rhs)):
        lhs.count == rhs.count && zip(lhs, rhs).allSatisfy { webNodesEqual($0.0, $0.1) }
    case (.element(let lhs), .element(let rhs)):
        lhs.tagName == rhs.tagName
            && lhs.attributes == rhs.attributes
            && lhs.styles == rhs.styles
            && lhs.styleVariants == rhs.styleVariants
            && lhs.children.count == rhs.children.count
            && zip(lhs.children, rhs.children).allSatisfy { webNodesEqual($0.0, $0.1) }
            && actionsEquivalent(lhs.action, rhs.action)
    default: false
    }
}

private func actionsEquivalent(_ lhs: ActionIntent?, _ rhs: ActionIntent?) -> Bool {
    switch (lhs, rhs) {
    case (nil, nil), (.closure, .closure): true
    case (.setState(let lhs), .setState(let rhs)): lhs == rhs
    default: false
    }
}

extension DOMPatch: CustomStringConvertible {
    var description: String {
        switch self {
        case .setText(let path, let value):
            "setText path=\(path.indices) value=\(quoted(value))"
        case .setAttribute(let path, let name, let value):
            "setAttribute path=\(path.indices) name=\(quoted(name)) value=\(quoted(value))"
        case .removeAttribute(let path, let name):
            "removeAttribute path=\(path.indices) name=\(quoted(name))"
        case .setStyle(let path, let name, let value):
            "setStyle path=\(path.indices) name=\(quoted(name)) value=\(quoted(value))"
        case .removeStyle(let path, let name):
            "removeStyle path=\(path.indices) name=\(quoted(name))"
        case .insertChild(let parent, let index, _):
            "insertChild parent=\(parent.indices) index=\(index)"
        case .removeChild(let parent, let index):
            "removeChild parent=\(parent.indices) index=\(index)"
        case .replaceNode(let path, _):
            "replaceNode path=\(path.indices)"
        case .replaceAction(let path, let action):
            if action == nil {
                "replaceAction path=\(path.indices) action=nil"
            } else {
                "replaceAction path=\(path.indices) action=present"
            }
        }
    }

    private func quoted(_ value: String) -> String {
        var result = "\""
        for character in value {
            switch character {
            case "\\": result += "\\\\"
            case "\"": result += "\\\""
            case "\n": result += "\\n"
            case "\r": result += "\\r"
            case "\t": result += "\\t"
            default: result.append(character)
            }
        }
        result += "\""
        return result
    }
}
