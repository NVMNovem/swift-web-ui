//
//  ViewNode.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

import SwiftCSS

/// Concrete renderer-neutral output from the SwiftWebUI DSL.
public indirect enum ViewNode {
    case empty
    case text(TextNode)
    case container(ContainerNode)
    case button(ButtonNode)
    case link(LinkNode)
    case image(ImageNode)
    case input(InputNode)
    case textArea(TextAreaNode)
    case spacer
    case tabControl(TabControlNode)
    case group([ViewNode])
    case modified(ModifiedNode)
}

extension ViewNode {
    var groupChildren: [ViewNode] {
        switch self {
        case .empty: []
        case .group(let children): children
        default: [self]
        }
    }
}
