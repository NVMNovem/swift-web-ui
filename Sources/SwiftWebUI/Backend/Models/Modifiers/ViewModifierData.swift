//
//  ViewModifierData.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftCSS
import SwiftHTML

public enum ViewModifierData {
    
    case cssClass(String)
    case id(String)
    case attribute(SwiftHTML.Attribute)
    case padding(Edge.Set, Length)
    case frame(width: Length?, height: Length?, maxWidth: Length?)
    case width(Length)
    case minWidth(Length)
    case maxWidth(Length)
    case height(Length)
    case minHeight(Length)
    case maxHeight(Length)
    case background(Background)
    case foregroundStyle(Color)
    case fontWeight(FontWeight.Value)
    case font(Font)
    case cornerRadius(Length)
    case clipShape(ClipShape)
    case border(SwiftCSS.Border)
    case shadow(BoxShadow)
    case gap(Length)
    case buttonStyleToken(ButtonStyleToken)
    case buttonStyle(AnyButtonStyle)
    case setState(ClientStateMutation)
}
