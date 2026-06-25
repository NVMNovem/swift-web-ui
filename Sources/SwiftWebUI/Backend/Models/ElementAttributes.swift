//
//  ElementAttributes.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftHTML

struct ElementAttributes {
    
    var htmlAttributes: [SwiftHTML.Attribute]
    var attributes: [SwiftHTML.Attribute] { htmlAttributes }
}
