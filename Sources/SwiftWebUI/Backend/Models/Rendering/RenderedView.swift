//
//  RenderedView.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

/// The rendered output of a SwiftWebUI view tree.
///
/// A rendered view keeps HTML content separate from CSS and JavaScript resources.
public struct RenderedView {
    
    public var content: RenderedContent
    public var resources: RenderedResources

    public init(content: RenderedContent, resources: RenderedResources) {
        self.content = content
        self.resources = resources
    }
}

public extension RenderedView {
    
    /// Returns the rendered HTML body content.
    func htmlString(prettyPrinted: Bool = false) -> String {
        content.htmlString(prettyPrinted: prettyPrinted)
    }

    /// Returns the collected CSS resources.
    func cssString(prettyPrinted: Bool = true) -> String {
        resources.cssString(prettyPrinted: prettyPrinted)
    }

    /// Returns the collected JavaScript resources.
    func jsString(prettyPrinted: Bool = true) -> String {
        resources.jsString(prettyPrinted: prettyPrinted)
    }
}
