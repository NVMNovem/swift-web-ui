//
//  View+Modifiers.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftCSS
import SwiftHTML

public extension View {
    // Modifiers stay as data so later renderers can emit extracted CSS classes
    // or JavaScript bindings without changing the SwiftWebUI view declarations.
    func `class`(_ name: String) -> ModifiedView<Self> {
        modified(.cssClass(name))
    }
    
    func id(_ value: String) -> ModifiedView<Self> {
        modified(.id(value))
    }
    
    func attribute(_ name: String, _ value: String) -> ModifiedView<Self> {
        modified(.attribute(SwiftHTML.Attribute(name, value)))
    }
    
    func display(_ value: DisplayValue) -> ModifiedView<Self> {
        modified(.display(value))
    }
    
    func margin(_ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.margin(.all, value))
    }
    
    func margin(_ edges: Edge.Set, _ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.margin(edges, value))
    }
    
    func padding(_ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.padding(.all, value))
    }
    
    func padding(_ edges: Edge.Set, _ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.padding(edges, value))
    }
    
    func frame(width: SwiftCSS.Length? = nil, height: SwiftCSS.Length? = nil, maxWidth: SwiftCSS.Length? = nil) -> ModifiedView<Self> {
        modified(.frame(width: width, height: height, maxWidth: maxWidth))
    }
    
    func width(_ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.width(value))
    }
    
    func minWidth(_ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.minWidth(value))
    }
    
    func maxWidth(_ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.maxWidth(value))
    }
    
    func height(_ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.height(value))
    }
    
    func minHeight(_ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.minHeight(value))
    }
    
    func maxHeight(_ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.maxHeight(value))
    }
    
    func background(_ background: Background) -> ModifiedView<Self> {
        modified(.background(background))
    }
    
    func background(_ color: SwiftCSS.Color) -> ModifiedView<Self> {
        background(Background(color))
    }
    
    /// Low-level escape hatch for raw CSS background values. Prefer `background(_:)`
    /// with `SwiftCSS.Color` for color tokens.
    func background(_ cssValue: String) -> ModifiedView<Self> {
        background(Background(cssValue))
    }
    
    func foregroundStyle(_ color: SwiftCSS.Color) -> ModifiedView<Self> {
        modified(.foregroundStyle(color))
    }
    
    func bold() -> ModifiedView<Self> {
        modified(.fontWeight(.bold))
    }
    
    func font(_ font: Font) -> ModifiedView<Self> {
        modified(.font(font))
    }

    func letterSpacing(_ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.letterSpacing(value))
    }

    func textTransform(_ value: TextTransform) -> ModifiedView<Self> {
        modified(.textTransform(value))
    }

    func lineHeight(_ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.lineHeight(value))
    }

    func textAlign(_ value: TextAlignment) -> ModifiedView<Self> {
        modified(.textAlign(value))
    }

    func textDecoration(_ value: TextDecoration) -> ModifiedView<Self> {
        modified(.textDecoration(value))
    }
    
    func cornerRadius(_ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.cornerRadius(value))
    }
    
    func clipShape(_ shape: ClipShape) -> ModifiedView<Self> {
        modified(.clipShape(shape))
    }
    
    func border(_ border: SwiftCSS.Border) -> ModifiedView<Self> {
        modified(.border(border))
    }
    
    func border(width: SwiftCSS.Length, style: BorderLineStyle = .solid, color: SwiftCSS.Color) -> ModifiedView<Self> {
        border(SwiftCSS.Border("\(width.rawValue) \(style.rawValue) \(color.rawValue)"))
    }
    
    /// Low-level escape hatch for raw CSS border values. Prefer
    /// `border(width:style:color:)` when the border can be expressed with typed parts.
    func border(_ cssValue: String) -> ModifiedView<Self> {
        border(SwiftCSS.Border(cssValue))
    }
    
    func shadow(_ shadow: BoxShadow) -> ModifiedView<Self> {
        modified(.shadow(shadow))
    }
    
    /// Low-level escape hatch for raw CSS box-shadow values. Prefer `BoxShadow`
    /// directly until a UI-level shadow token model is needed.
    func shadow(_ cssValue: String) -> ModifiedView<Self> {
        shadow(BoxShadow(cssValue))
    }
    
    func gap(_ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.gap(value))
    }
    
    func buttonStyle(_ token: ButtonStyleToken) -> ModifiedView<Self> {
        modified(.buttonStyleToken(token))
    }
    
    func buttonStyle<S: ButtonStyle>(_ style: S) -> ModifiedView<Self> {
        modified(.buttonStyle(AnyButtonStyle(style)))
    }
    
    // Temporary lower-level action model. A future SwiftUI-like Button closure
    // runtime can lower Binding writes into this same client-state intent.
    func setState(_ key: String, to value: String) -> ModifiedView<Self> {
        modified(.setState(ClientStateMutation(key: key, value: value)))
    }
    
    func set<Value: ClientStateValue>(_ binding: Binding<Value>, to value: Value) -> ModifiedView<Self> {
        setClientState(binding, to: value.clientStateValue)
    }
    
    func set<Value: RawRepresentable>(_ binding: Binding<Value>, to value: Value) -> ModifiedView<Self> where Value.RawValue == String {
        setClientState(binding, to: value.rawValue)
    }
    
    func set<Value: RawRepresentable>(_ binding: Binding<Value>, to value: Value) -> ModifiedView<Self> where Value.RawValue == Int {
        setClientState(binding, to: String(value.rawValue))
    }
    
    private func modified(_ modifier: ViewModifierData) -> ModifiedView<Self> {
        ModifiedView(content: self, modifiers: [modifier])
    }
    
    private func setClientState<Value>(_ binding: Binding<Value>, to value: String) -> ModifiedView<Self> {
        guard let clientState = binding.clientState else {
            return setState("", to: value)
        }
        
        return setState(clientState.key, to: value)
    }
}

public extension ModifiedView {
    func `class`(_ name: String) -> ModifiedView<Content> {
        appending(.cssClass(name))
    }
    
    func id(_ value: String) -> ModifiedView<Content> {
        appending(.id(value))
    }
    
    func attribute(_ name: String, _ value: String) -> ModifiedView<Content> {
        appending(.attribute(SwiftHTML.Attribute(name, value)))
    }
    
    func display(_ value: DisplayValue) -> ModifiedView<Content> {
        appending(.display(value))
    }
    
    func margin(_ value: SwiftCSS.Length) -> ModifiedView<Content> {
        appending(.margin(.all, value))
    }
    
    func margin(_ edges: Edge.Set, _ value: SwiftCSS.Length) -> ModifiedView<Content> {
        appending(.margin(edges, value))
    }
    
    func padding(_ value: SwiftCSS.Length) -> ModifiedView<Content> {
        appending(.padding(.all, value))
    }
    
    func padding(_ edges: Edge.Set, _ value: SwiftCSS.Length) -> ModifiedView<Content> {
        appending(.padding(edges, value))
    }
    
    func frame(width: SwiftCSS.Length? = nil, height: SwiftCSS.Length? = nil, maxWidth: SwiftCSS.Length? = nil) -> ModifiedView<Content> {
        appending(.frame(width: width, height: height, maxWidth: maxWidth))
    }
    
    func width(_ value: SwiftCSS.Length) -> ModifiedView<Content> {
        appending(.width(value))
    }
    
    func minWidth(_ value: SwiftCSS.Length) -> ModifiedView<Content> {
        appending(.minWidth(value))
    }
    
    func maxWidth(_ value: SwiftCSS.Length) -> ModifiedView<Content> {
        appending(.maxWidth(value))
    }
    
    func height(_ value: SwiftCSS.Length) -> ModifiedView<Content> {
        appending(.height(value))
    }
    
    func minHeight(_ value: SwiftCSS.Length) -> ModifiedView<Content> {
        appending(.minHeight(value))
    }
    
    func maxHeight(_ value: SwiftCSS.Length) -> ModifiedView<Content> {
        appending(.maxHeight(value))
    }
    
    func background(_ background: Background) -> ModifiedView<Content> {
        appending(.background(background))
    }
    
    func background(_ color: SwiftCSS.Color) -> ModifiedView<Content> {
        background(Background(color))
    }
    
    /// Low-level escape hatch for raw CSS background values. Prefer `background(_:)`
    /// with `SwiftCSS.Color` for color tokens.
    func background(_ cssValue: String) -> ModifiedView<Content> {
        background(Background(cssValue))
    }
    
    func foregroundStyle(_ color: SwiftCSS.Color) -> ModifiedView<Content> {
        appending(.foregroundStyle(color))
    }
    
    func bold() -> ModifiedView<Content> {
        appending(.fontWeight(.bold))
    }
    
    func font(_ font: Font) -> ModifiedView<Content> {
        appending(.font(font))
    }

    func letterSpacing(_ value: SwiftCSS.Length) -> ModifiedView<Content> {
        appending(.letterSpacing(value))
    }

    func textTransform(_ value: TextTransform) -> ModifiedView<Content> {
        appending(.textTransform(value))
    }

    func lineHeight(_ value: SwiftCSS.Length) -> ModifiedView<Content> {
        appending(.lineHeight(value))
    }

    func textAlign(_ value: TextAlignment) -> ModifiedView<Content> {
        appending(.textAlign(value))
    }

    func textDecoration(_ value: TextDecoration) -> ModifiedView<Content> {
        appending(.textDecoration(value))
    }
    
    func cornerRadius(_ value: SwiftCSS.Length) -> ModifiedView<Content> {
        appending(.cornerRadius(value))
    }
    
    func clipShape(_ shape: ClipShape) -> ModifiedView<Content> {
        appending(.clipShape(shape))
    }
    
    func border(_ border: SwiftCSS.Border) -> ModifiedView<Content> {
        appending(.border(border))
    }
    
    func border(width: SwiftCSS.Length, style: BorderLineStyle = .solid, color: SwiftCSS.Color) -> ModifiedView<Content> {
        border(SwiftCSS.Border("\(width.rawValue) \(style.rawValue) \(color.rawValue)"))
    }
    
    /// Low-level escape hatch for raw CSS border values. Prefer
    /// `border(width:style:color:)` when the border can be expressed with typed parts.
    func border(_ cssValue: String) -> ModifiedView<Content> {
        border(SwiftCSS.Border(cssValue))
    }
    
    func shadow(_ shadow: BoxShadow) -> ModifiedView<Content> {
        appending(.shadow(shadow))
    }
    
    /// Low-level escape hatch for raw CSS box-shadow values. Prefer `BoxShadow`
    /// directly until a UI-level shadow token model is needed.
    func shadow(_ cssValue: String) -> ModifiedView<Content> {
        shadow(BoxShadow(cssValue))
    }
    
    func gap(_ value: SwiftCSS.Length) -> ModifiedView<Content> {
        appending(.gap(value))
    }
    
    func buttonStyle(_ token: ButtonStyleToken) -> ModifiedView<Content> {
        appending(.buttonStyleToken(token))
    }
    
    func buttonStyle<S: ButtonStyle>(_ style: S) -> ModifiedView<Content> {
        appending(.buttonStyle(AnyButtonStyle(style)))
    }
    
    func setState(_ key: String, to value: String) -> ModifiedView<Content> {
        appending(.setState(ClientStateMutation(key: key, value: value)))
    }
    
    func set<Value: ClientStateValue>(_ binding: Binding<Value>, to value: Value) -> ModifiedView<Content> {
        setClientState(binding, to: value.clientStateValue)
    }
    
    func set<Value: RawRepresentable>(_ binding: Binding<Value>, to value: Value) -> ModifiedView<Content> where Value.RawValue == String {
        setClientState(binding, to: value.rawValue)
    }
    
    func set<Value: RawRepresentable>(_ binding: Binding<Value>, to value: Value) -> ModifiedView<Content> where Value.RawValue == Int {
        setClientState(binding, to: String(value.rawValue))
    }
    
    private func appending(_ modifier: ViewModifierData) -> ModifiedView<Content> {
        ModifiedView(content: content, modifiers: modifiers + [modifier])
    }
    
    private func setClientState<Value>(_ binding: Binding<Value>, to value: String) -> ModifiedView<Content> {
        guard let clientState = binding.clientState else {
            return setState("", to: value)
        }
        
        return setState(clientState.key, to: value)
    }
}
