//
//  RenderedContent.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftHTML

public struct RenderedContent {
    
    public var html: [any SwiftHTML.HTMLNode]

    public init(html: [any SwiftHTML.HTMLNode]) {
        self.html = html
    }
}

public extension RenderedContent {
    
    func htmlString(prettyPrinted: Bool = false) -> String {
        html.map { $0.render(prettyPrinted: prettyPrinted) }.joined()
    }
}
