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
    /// Adds an HTML class to the rendered element.
    func `class`(_ name: String) -> ModifiedView<Self> {
        modified(.cssClass(name))
    }
    
    /// Adds an HTML `id` to the rendered element.
    func id(_ value: String) -> ModifiedView<Self> {
        modified(.id(value))
    }
    
    /// Adds a raw HTML attribute to the rendered element.
    func attribute(_ name: String, _ value: String) -> ModifiedView<Self> {
        modified(.attribute(SwiftHTML.Attribute(name, value)))
    }
    
    /// Applies a CSS display value.
    func display(_ value: DisplayValue) -> ModifiedView<Self> {
        modified(.display(value))
    }

    /// Applies CSS grid-template-columns.
    func gridTemplateColumns(_ value: String) -> ModifiedView<Self> {
        modified(.gridTemplateColumns(value))
    }

    /// Applies CSS justify-content.
    func justifyContent(_ value: JustifyContentValue) -> ModifiedView<Self> {
        modified(.justifyContent(value))
    }

    /// Applies CSS flex-wrap.
    func flexWrap(_ value: FlexWrapValue) -> ModifiedView<Self> {
        modified(.flexWrap(value))
    }
    
    /// Applies margin to all edges.
    func margin(_ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.margin(.all, value))
    }
    
    func margin(_ edges: Edge.Set, _ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.margin(edges, value))
    }
    
    /// Applies padding to all edges.
    func padding(_ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.padding(.all, value))
    }
    
    func padding(_ edges: Edge.Set, _ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.padding(edges, value))
    }
    
    /// Applies width, height, and maximum width constraints.
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
    
    /// Applies a background value.
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
    
    /// Applies a foreground text color.
    func foregroundStyle(_ color: SwiftCSS.Color) -> ModifiedView<Self> {
        modified(.foregroundStyle(color))
    }
    
    /// Applies bold font weight.
    func bold() -> ModifiedView<Self> {
        modified(.fontWeight(.bold))
    }
    
    /// Applies a font token.
    func font(_ font: Font) -> ModifiedView<Self> {
        modified(.font(font))
    }

    /// Applies CSS letter spacing.
    func letterSpacing(_ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.letterSpacing(value))
    }

    /// Applies CSS text transformation.
    func textTransform(_ value: TextTransform) -> ModifiedView<Self> {
        modified(.textTransform(value))
    }

    /// Applies CSS line height.
    func lineHeight(_ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.lineHeight(value))
    }

    /// Applies CSS text alignment.
    func textAlign(_ value: TextAlignment) -> ModifiedView<Self> {
        modified(.textAlign(value))
    }

    /// Applies CSS text decoration.
    func textDecoration(_ value: TextDecoration) -> ModifiedView<Self> {
        modified(.textDecoration(value))
    }

    /// Applies CSS opacity.
    func opacity(_ value: Double) -> ModifiedView<Self> {
        modified(.opacity(value))
    }

    /// Applies CSS transform.
    func transform(_ value: String) -> ModifiedView<Self> {
        modified(.transform(value))
    }

    /// Applies CSS transition.
    func transition(_ value: String) -> ModifiedView<Self> {
        modified(.transition(value))
    }

    /// Applies CSS backdrop-filter.
    func backdropFilter(_ value: String) -> ModifiedView<Self> {
        modified(.backdropFilter(value))
    }

    /// Applies CSS overflow.
    func overflow(_ value: OverflowValue) -> ModifiedView<Self> {
        modified(.overflow(value))
    }

    /// Applies CSS object-fit.
    func objectFit(_ value: ObjectFitValue) -> ModifiedView<Self> {
        modified(.objectFit(value))
    }

    /// Applies CSS pointer-events.
    func pointerEvents(_ value: PointerEventsValue) -> ModifiedView<Self> {
        modified(.pointerEvents(value))
    }

    /// Applies CSS cursor.
    func cursor(_ value: CursorValue) -> ModifiedView<Self> {
        modified(.cursor(value))
    }

    /// Applies CSS position.
    func position(_ value: PositionValue) -> ModifiedView<Self> {
        modified(.position(value))
    }

    /// Applies CSS top offset.
    func top(_ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.top(value))
    }

    /// Applies CSS right offset.
    func right(_ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.right(value))
    }

    /// Applies CSS bottom offset.
    func bottom(_ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.bottom(value))
    }

    /// Applies CSS left offset.
    func left(_ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.left(value))
    }

    /// Applies CSS z-index.
    func zIndex(_ value: Int) -> ModifiedView<Self> {
        modified(.zIndex(value))
    }

    /// Applies CSS resize.
    func resize(_ value: ResizeValue) -> ModifiedView<Self> {
        modified(.resize(value))
    }

    /// Applies CSS outline.
    func outline(_ value: OutlineValue) -> ModifiedView<Self> {
        modified(.outline(value))
    }

    /// Applies CSS scroll-margin-top.
    func scrollMarginTop(_ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.scrollMarginTop(value))
    }
    
    /// Applies a border radius.
    func cornerRadius(_ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.cornerRadius(value))
    }
    
    /// Applies generated clipping style for the given shape.
    func clipShape(_ shape: ClipShape) -> ModifiedView<Self> {
        modified(.clipShape(shape))
    }
    
    /// Applies a SwiftCSS border value.
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
    
    /// Applies a SwiftCSS box-shadow value.
    func shadow(_ shadow: BoxShadow) -> ModifiedView<Self> {
        modified(.shadow(shadow))
    }
    
    /// Low-level escape hatch for raw CSS box-shadow values. Prefer `BoxShadow`
    /// directly until a UI-level shadow token model is needed.
    func shadow(_ cssValue: String) -> ModifiedView<Self> {
        shadow(BoxShadow(cssValue))
    }
    
    /// Applies CSS gap.
    func gap(_ value: SwiftCSS.Length) -> ModifiedView<Self> {
        modified(.gap(value))
    }
    
    /// Applies a reusable button style token.
    func buttonStyle(_ token: ButtonStyleToken) -> ModifiedView<Self> {
        modified(.buttonStyleToken(token))
    }
    
    /// Applies a static button style.
    func buttonStyle<S: ButtonStyle>(_ style: S) -> ModifiedView<Self> {
        modified(.buttonStyle(AnyButtonStyle(style)))
    }
    
    // Temporary lower-level action model. A future SwiftUI-like Button closure
    // runtime can lower Binding writes into this same client-state intent.
    /// Emits generated client-state mutation attributes.
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

    func gridTemplateColumns(_ value: String) -> ModifiedView<Content> {
        appending(.gridTemplateColumns(value))
    }

    func justifyContent(_ value: JustifyContentValue) -> ModifiedView<Content> {
        appending(.justifyContent(value))
    }

    func flexWrap(_ value: FlexWrapValue) -> ModifiedView<Content> {
        appending(.flexWrap(value))
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

    func opacity(_ value: Double) -> ModifiedView<Content> {
        appending(.opacity(value))
    }

    func transform(_ value: String) -> ModifiedView<Content> {
        appending(.transform(value))
    }

    func transition(_ value: String) -> ModifiedView<Content> {
        appending(.transition(value))
    }

    func backdropFilter(_ value: String) -> ModifiedView<Content> {
        appending(.backdropFilter(value))
    }

    func overflow(_ value: OverflowValue) -> ModifiedView<Content> {
        appending(.overflow(value))
    }

    func objectFit(_ value: ObjectFitValue) -> ModifiedView<Content> {
        appending(.objectFit(value))
    }

    func pointerEvents(_ value: PointerEventsValue) -> ModifiedView<Content> {
        appending(.pointerEvents(value))
    }

    func cursor(_ value: CursorValue) -> ModifiedView<Content> {
        appending(.cursor(value))
    }

    func position(_ value: PositionValue) -> ModifiedView<Content> {
        appending(.position(value))
    }

    func top(_ value: SwiftCSS.Length) -> ModifiedView<Content> {
        appending(.top(value))
    }

    func right(_ value: SwiftCSS.Length) -> ModifiedView<Content> {
        appending(.right(value))
    }

    func bottom(_ value: SwiftCSS.Length) -> ModifiedView<Content> {
        appending(.bottom(value))
    }

    func left(_ value: SwiftCSS.Length) -> ModifiedView<Content> {
        appending(.left(value))
    }

    func zIndex(_ value: Int) -> ModifiedView<Content> {
        appending(.zIndex(value))
    }

    func resize(_ value: ResizeValue) -> ModifiedView<Content> {
        appending(.resize(value))
    }

    func outline(_ value: OutlineValue) -> ModifiedView<Content> {
        appending(.outline(value))
    }

    func scrollMarginTop(_ value: SwiftCSS.Length) -> ModifiedView<Content> {
        appending(.scrollMarginTop(value))
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
