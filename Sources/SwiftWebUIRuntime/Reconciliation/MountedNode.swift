//
//  MountedNode.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

@_spi(Rendering) import SwiftWebUI

indirect enum MountedNode<Handle, ActionRegistration> {
    case empty
    case text(MountedTextNode<Handle>)
    case element(MountedElementNode<Handle, ActionRegistration>)
    case fragment(MountedFragmentNode<Handle, ActionRegistration>)

    var children: [MountedNode] {
        get {
            switch self {
            case .element(let element): element.children
            case .fragment(let fragment): fragment.children
            case .empty, .text: []
            }
        }
        set {
            switch self {
            case .element(let element): element.children = newValue
            case .fragment(let fragment): fragment.children = newValue
            case .empty, .text: preconditionFailure("Only mounted containers have children")
            }
        }
    }

    var firstDOMHandle: Handle? {
        switch self {
        case .empty: nil
        case .text(let text): text.handle
        case .element(let element): element.handle
        case .fragment(let fragment):
            fragment.children.lazy.compactMap(\.firstDOMHandle).first
        }
    }

    var topLevelDOMHandles: [Handle] {
        switch self {
        case .empty: []
        case .text(let text): [text.handle]
        case .element(let element): [element.handle]
        case .fragment(let fragment): fragment.children.flatMap(\.topLevelDOMHandles)
        }
    }
}

final class MountedTextNode<Handle> {
    let handle: Handle
    var value: String

    init(handle: Handle, value: String) {
        self.handle = handle
        self.value = value
    }
}

final class MountedElementNode<Handle, ActionRegistration> {
    let handle: Handle
    let tagName: String
    var attributes: [WebAttribute]
    var styles: [WebStyleDeclaration]
    var children: [MountedNode<Handle, ActionRegistration>]
    var actionRegistration: ActionRegistration?

    init(
        handle: Handle,
        tagName: String,
        attributes: [WebAttribute],
        styles: [WebStyleDeclaration],
        children: [MountedNode<Handle, ActionRegistration>],
        actionRegistration: ActionRegistration?
    ) {
        self.handle = handle
        self.tagName = tagName
        self.attributes = attributes
        self.styles = styles
        self.children = children
        self.actionRegistration = actionRegistration
    }
}

final class MountedFragmentNode<Handle, ActionRegistration> {
    var children: [MountedNode<Handle, ActionRegistration>]

    init(children: [MountedNode<Handle, ActionRegistration>]) {
        self.children = children
    }
}
