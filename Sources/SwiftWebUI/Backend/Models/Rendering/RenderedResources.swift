//
//  RenderedResources.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

/// CSS and JavaScript resources collected while rendering a view tree.
public struct RenderedResources {
    
    public var styles: [StyleResource]
    public var scripts: [ScriptResource]

    public init(styles: [StyleResource] = [], scripts: [ScriptResource] = []) {
        self.styles = styles
        self.scripts = scripts
    }
}

public extension RenderedResources {
    
    /// Returns all style resources as one CSS string.
    func cssString(prettyPrinted: Bool = true) -> String {
        styles
            .map(\.content)
            .filter { !$0.isEmpty }
            .map { prettyPrinted ? $0 : compactResourceContent($0) }
            .joined(separator: prettyPrinted ? "\n\n" : "")
    }

    /// Returns all script resources as one JavaScript string.
    func jsString(prettyPrinted: Bool = true) -> String {
        scripts
            .map(\.content)
            .filter { !$0.isEmpty }
            .map { prettyPrinted ? $0 : compactResourceContent($0) }
            .joined(separator: prettyPrinted ? "\n\n" : "")
    }
}

private func compactResourceContent(_ content: String) -> String {
    content.split { $0.isWhitespace }.joined(separator: " ")
}
