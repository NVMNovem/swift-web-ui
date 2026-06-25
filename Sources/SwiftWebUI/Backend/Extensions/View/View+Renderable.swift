//
//  View+Renderable.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftHTML

extension View {
    
    func renderSwiftHTML(context: inout RenderContext) -> [any SwiftHTML.HTMLNode] {
        if let renderable = self as? SwiftHTMLRenderable {
            return renderable.renderSwiftHTML(context: &context)
        }
        
        return body.renderSwiftHTML(context: &context)
    }
}

