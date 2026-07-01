//
//  ViewModifierData.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftCSS
import SwiftHTML

/// Data representation of SwiftWebUI modifiers before rendering.
///
/// Renderers lower this intent into SwiftHTML attributes, SwiftCSS declarations,
/// and generated client-state resources.
public enum ViewModifierData {
    
    case cssClass(String)
    case id(String)
    case attribute(SwiftHTML.Attribute)
    case display(DisplayValue)
    case margin(Edge.Set, SwiftCSS.Length)
    case padding(Edge.Set, SwiftCSS.Length)
    case frame(width: SwiftCSS.Length?, height: SwiftCSS.Length?, maxWidth: SwiftCSS.Length?)
    case width(SwiftCSS.Length)
    case minWidth(SwiftCSS.Length)
    case maxWidth(SwiftCSS.Length)
    case height(SwiftCSS.Length)
    case minHeight(SwiftCSS.Length)
    case maxHeight(SwiftCSS.Length)
    case background(Background)
    case foregroundStyle(SwiftCSS.Color)
    case fontWeight(FontWeight.Value)
    case font(Font)
    case letterSpacing(SwiftCSS.Length)
    case textTransform(TextTransform)
    case lineHeight(SwiftCSS.Length)
    case textAlign(TextAlignment)
    case textDecoration(TextDecoration)
    case cornerRadius(SwiftCSS.Length)
    case clipShape(ClipShape)
    case border(SwiftCSS.Border)
    case shadow(BoxShadow)
    case gap(SwiftCSS.Length)
    case buttonStyleToken(ButtonStyleToken)
    case buttonStyle(AnyButtonStyle)
    case setState(ClientStateMutation)
}
