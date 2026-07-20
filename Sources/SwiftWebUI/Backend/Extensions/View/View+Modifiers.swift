//
//  View+Modifiers.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftCSS

public extension View {
    func `class`(_ name: String) -> ModifiedView<Self> { modified(.cssClass(name)) }
    func id(_ value: String) -> ModifiedView<Self> { modified(.identifier(value)) }
    func attribute(_ name: String, _ value: String) -> ModifiedView<Self> { modified(.attribute(name: name, value: value)) }
    func bindText(_ fieldName: String) -> ModifiedView<Self> { modified(.bindText(fieldName)) }
    func bindAttribute(_ name: String, _ fieldName: String) -> ModifiedView<Self> { modified(.bindAttribute(name: name, field: fieldName)) }
    func display(_ value: DisplayValue) -> ModifiedView<Self> { modified(.display(value)) }
    func gridTemplateColumns(_ value: String) -> ModifiedView<Self> { modified(.gridTemplateColumns(value)) }
    func justifyContent(_ value: JustifyContentValue) -> ModifiedView<Self> { modified(.justifyContent(value)) }
    func flexWrap(_ value: FlexWrapValue) -> ModifiedView<Self> { modified(.flexWrap(value)) }
    func margin(_ value: SwiftCSS.Length) -> ModifiedView<Self> { modified(.margin(.all, value)) }
    func margin(_ edges: Edge.Set, _ value: SwiftCSS.Length) -> ModifiedView<Self> { modified(.margin(edges, value)) }
    func padding(_ value: SwiftCSS.Length) -> ModifiedView<Self> { modified(.padding(.all, value)) }
    func padding(_ edges: Edge.Set, _ value: SwiftCSS.Length) -> ModifiedView<Self> { modified(.padding(edges, value)) }
    func frame(width: SwiftCSS.Length? = nil, height: SwiftCSS.Length? = nil, maxWidth: SwiftCSS.Length? = nil) -> ModifiedView<Self> { modified(.frame(width: width, height: height, maxWidth: maxWidth)) }
    func width(_ value: SwiftCSS.Length) -> ModifiedView<Self> { modified(.width(value)) }
    func minWidth(_ value: SwiftCSS.Length) -> ModifiedView<Self> { modified(.minWidth(value)) }
    func maxWidth(_ value: SwiftCSS.Length) -> ModifiedView<Self> { modified(.maxWidth(value)) }
    func height(_ value: SwiftCSS.Length) -> ModifiedView<Self> { modified(.height(value)) }
    func minHeight(_ value: SwiftCSS.Length) -> ModifiedView<Self> { modified(.minHeight(value)) }
    func maxHeight(_ value: SwiftCSS.Length) -> ModifiedView<Self> { modified(.maxHeight(value)) }
    func background(_ background: Background) -> ModifiedView<Self> { modified(.background(background)) }
    func background(_ color: SwiftCSS.Color) -> ModifiedView<Self> { background(Background(color)) }
    func background(_ cssValue: String) -> ModifiedView<Self> { background(Background(cssValue)) }
    func foregroundStyle(_ color: SwiftCSS.Color) -> ModifiedView<Self> { modified(.foregroundStyle(color)) }
    func bold() -> ModifiedView<Self> { modified(.fontWeight(.bold)) }
    func font(_ font: Font) -> ModifiedView<Self> { modified(.font(font)) }
    func letterSpacing(_ value: SwiftCSS.Length) -> ModifiedView<Self> { modified(.letterSpacing(value)) }
    func textTransform(_ value: TextTransform) -> ModifiedView<Self> { modified(.textTransform(value)) }
    func lineHeight(_ value: SwiftCSS.Length) -> ModifiedView<Self> { modified(.lineHeight(value)) }
    func textAlign(_ value: TextAlignment) -> ModifiedView<Self> { modified(.textAlign(value)) }
    func textDecoration(_ value: TextDecoration) -> ModifiedView<Self> { modified(.textDecoration(value)) }
    func opacity(_ value: Double) -> ModifiedView<Self> { modified(.opacity(value)) }
    func transform(_ value: String) -> ModifiedView<Self> { modified(.transform(value)) }
    func transition(_ value: String) -> ModifiedView<Self> { modified(.transition(value)) }
    func backdropFilter(_ value: String) -> ModifiedView<Self> { modified(.backdropFilter(value)) }
    func overflow(_ value: OverflowValue) -> ModifiedView<Self> { modified(.overflow(value)) }
    func objectFit(_ value: ObjectFitValue) -> ModifiedView<Self> { modified(.objectFit(value)) }
    func pointerEvents(_ value: PointerEventsValue) -> ModifiedView<Self> { modified(.pointerEvents(value)) }
    func cursor(_ value: CursorValue) -> ModifiedView<Self> { modified(.cursor(value)) }
    func position(_ value: PositionValue) -> ModifiedView<Self> { modified(.position(value)) }
    func top(_ value: SwiftCSS.Length) -> ModifiedView<Self> { modified(.top(value)) }
    func right(_ value: SwiftCSS.Length) -> ModifiedView<Self> { modified(.right(value)) }
    func bottom(_ value: SwiftCSS.Length) -> ModifiedView<Self> { modified(.bottom(value)) }
    func left(_ value: SwiftCSS.Length) -> ModifiedView<Self> { modified(.left(value)) }
    func zIndex(_ value: Int) -> ModifiedView<Self> { modified(.zIndex(value)) }
    func resize(_ value: ResizeValue) -> ModifiedView<Self> { modified(.resize(value)) }
    func outline(_ value: OutlineValue) -> ModifiedView<Self> { modified(.outline(value)) }
    func scrollMarginTop(_ value: SwiftCSS.Length) -> ModifiedView<Self> { modified(.scrollMarginTop(value)) }
    func cornerRadius(_ value: SwiftCSS.Length) -> ModifiedView<Self> { modified(.cornerRadius(value)) }
    func clipShape(_ shape: ClipShape) -> ModifiedView<Self> { modified(.clipShape(shape)) }
    func border(_ border: SwiftCSS.Border) -> ModifiedView<Self> { modified(.border(border)) }
    func border(width: SwiftCSS.Length, style: BorderLineStyle = .solid, color: SwiftCSS.Color) -> ModifiedView<Self> { modified(.borderParts(width: width, style: style, color: color)) }
    func border(_ cssValue: String) -> ModifiedView<Self> { border(SwiftCSS.Border(cssValue)) }
    func shadow(_ shadow: BoxShadow) -> ModifiedView<Self> { modified(.shadow(shadow)) }
    func shadow(_ cssValue: String) -> ModifiedView<Self> { shadow(BoxShadow(cssValue)) }
    func gap(_ value: SwiftCSS.Length) -> ModifiedView<Self> { modified(.gap(value)) }
    func buttonStyle(_ token: ButtonStyleToken) -> ModifiedView<Self> { modified(.buttonStyle(token)) }

    func setState(_ key: String, to value: String) -> ModifiedView<Self> {
        modified(.setState(.init(target: .named(key), value: .string(value))))
    }

    func set<Value: ClientStateValue>(
        _ binding: Binding<Value>,
        to value: Value
    ) -> ModifiedView<Self> {
        modified(.setState(.init(target: binding.stateTarget, value: value.clientValue)))
    }

    func set<Value: RawRepresentable>(
        _ binding: Binding<Value>,
        to value: Value
    ) -> ModifiedView<Self> where Value.RawValue == String {
        modified(.setState(.init(target: binding.stateTarget, value: .string(value.rawValue))))
    }

    func set<Value: RawRepresentable>(
        _ binding: Binding<Value>,
        to value: Value
    ) -> ModifiedView<Self> where Value.RawValue == Int {
        modified(.setState(.init(target: binding.stateTarget, value: .integer(value.rawValue))))
    }

    private func modified(_ modifier: ViewModifierNode) -> ModifiedView<Self> {
        ModifiedView(content: self, modifiers: [modifier])
    }
}

private extension Binding {
    var stateTarget: ClientStateTarget {
        if let stateIdentity {
            return .state(stateIdentity)
        }
        return .named("")
    }
}
