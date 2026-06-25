//
//  SwiftHTMLRenderable.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 25/06/2026.
//

import SwiftHTML

protocol SwiftHTMLRenderable {
    
    func renderSwiftHTML(context: inout RenderContext) -> [any SwiftHTML.HTMLNode]
}
