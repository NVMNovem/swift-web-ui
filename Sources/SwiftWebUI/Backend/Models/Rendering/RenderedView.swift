//
//  RenderedView.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public struct RenderedView {
    
    public var content: RenderedContent
    public var resources: RenderedResources

    public init(content: RenderedContent, resources: RenderedResources) {
        self.content = content
        self.resources = resources
    }
}

public extension RenderedView {
    
    func htmlString(prettyPrinted: Bool = false) -> String {
        content.htmlString(prettyPrinted: prettyPrinted)
    }

    func cssString(prettyPrinted: Bool = true) -> String {
        resources.cssString(prettyPrinted: prettyPrinted)
    }

    func jsString(prettyPrinted: Bool = true) -> String {
        resources.jsString(prettyPrinted: prettyPrinted)
    }
}
