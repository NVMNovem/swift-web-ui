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
    
    func padding(_ value: Length) -> ModifiedView<Self> {
        modified(.padding(.all, value))
    }
    
    func padding(_ edges: Edge.Set, _ value: Length) -> ModifiedView<Self> {
        modified(.padding(edges, value))
    }
    
    func frame(width: Length? = nil, height: Length? = nil, maxWidth: Length? = nil) -> ModifiedView<Self> {
        modified(.frame(width: width, height: height, maxWidth: maxWidth))
    }
    
    func background(_ background: Background) -> ModifiedView<Self> {
        modified(.background(background))
    }
    
    func background(_ color: Color) -> ModifiedView<Self> {
        background(Background(color))
    }
    
    func foregroundStyle(_ color: Color) -> ModifiedView<Self> {
        modified(.foregroundStyle(color))
    }
    
    func bold() -> ModifiedView<Self> {
        modified(.fontWeight(.bold))
    }
    
    func font(_ token: FontToken) -> ModifiedView<Self> {
        modified(.font(token))
    }
    
    func cornerRadius(_ value: Length) -> ModifiedView<Self> {
        modified(.cornerRadius(value))
    }
    
    func clipShape(_ shape: ClipShape) -> ModifiedView<Self> {
        modified(.clipShape(shape))
    }
    
    func border(_ border: SwiftCSS.Border) -> ModifiedView<Self> {
        modified(.border(border))
    }
    
    func border(_ cssValue: String) -> ModifiedView<Self> {
        border(SwiftCSS.Border(cssValue))
    }
    
    func shadow(_ shadow: BoxShadow) -> ModifiedView<Self> {
        modified(.shadow(shadow))
    }
    
    func shadow(_ cssValue: String) -> ModifiedView<Self> {
        shadow(BoxShadow(cssValue))
    }
    
    func gap(_ value: Length) -> ModifiedView<Self> {
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
    
    func padding(_ value: Length) -> ModifiedView<Content> {
        appending(.padding(.all, value))
    }
    
    func padding(_ edges: Edge.Set, _ value: Length) -> ModifiedView<Content> {
        appending(.padding(edges, value))
    }
    
    func frame(width: Length? = nil, height: Length? = nil, maxWidth: Length? = nil) -> ModifiedView<Content> {
        appending(.frame(width: width, height: height, maxWidth: maxWidth))
    }
    
    func background(_ background: Background) -> ModifiedView<Content> {
        appending(.background(background))
    }
    
    func background(_ color: Color) -> ModifiedView<Content> {
        background(Background(color))
    }
    
    func foregroundStyle(_ color: Color) -> ModifiedView<Content> {
        appending(.foregroundStyle(color))
    }
    
    func bold() -> ModifiedView<Content> {
        appending(.fontWeight(.bold))
    }
    
    func font(_ token: FontToken) -> ModifiedView<Content> {
        appending(.font(token))
    }
    
    func cornerRadius(_ value: Length) -> ModifiedView<Content> {
        appending(.cornerRadius(value))
    }
    
    func clipShape(_ shape: ClipShape) -> ModifiedView<Content> {
        appending(.clipShape(shape))
    }
    
    func border(_ border: SwiftCSS.Border) -> ModifiedView<Content> {
        appending(.border(border))
    }
    
    func border(_ cssValue: String) -> ModifiedView<Content> {
        border(SwiftCSS.Border(cssValue))
    }
    
    func shadow(_ shadow: BoxShadow) -> ModifiedView<Content> {
        appending(.shadow(shadow))
    }
    
    func shadow(_ cssValue: String) -> ModifiedView<Content> {
        shadow(BoxShadow(cssValue))
    }
    
    func gap(_ value: Length) -> ModifiedView<Content> {
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
