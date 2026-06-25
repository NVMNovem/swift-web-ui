//
//  RenderedResources.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public struct RenderedResources {
    
    public var styles: [StyleResource]
    public var scripts: [ScriptResource]

    public init(styles: [StyleResource] = [], scripts: [ScriptResource] = []) {
        self.styles = styles
        self.scripts = scripts
    }
}

public extension RenderedResources {
    
    func cssString(prettyPrinted: Bool = true) -> String {
        styles
            .map(\.content)
            .filter { !$0.isEmpty }
            .map { prettyPrinted ? $0 : compactResourceContent($0) }
            .joined(separator: prettyPrinted ? "\n\n" : "")
    }

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
