//
//  ElementAttributes.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftCSS
import SwiftHTML

/// Internal rendering state passed through a SwiftWebUI render pass.
///
/// Public mainly for renderer integration points. User code normally interacts
/// with ``HTMLRenderer`` and ``RenderedView`` instead.
public struct RenderContext {
    var modifiers: [ViewModifierData]
    private var resources: RenderResourceStorage

    var hasPendingModifiers: Bool {
        !modifiers.isEmpty
    }

    public init(modifiers: [ViewModifierData] = []) {
        self.modifiers = modifiers
        self.resources = RenderResourceStorage()
    }

    private init(modifiers: [ViewModifierData], resources: RenderResourceStorage) {
        self.modifiers = modifiers
        self.resources = resources
    }

    func appending(_ newModifiers: [ViewModifierData]) -> RenderContext {
        RenderContext(modifiers: modifiers + newModifiers, resources: resources)
    }

    func clearingModifiers() -> RenderContext {
        RenderContext(modifiers: [], resources: resources)
    }

    mutating func className(for properties: [any CSSProperty], scope: ResourceScope = .global) -> String {
        resources.styleRegistry.className(for: properties, scope: scope)
    }
    
    mutating func registerClientStateRuntime() {
        guard !resources.scriptIDs.contains(ClientStateRuntime.scriptID) else {
            return
        }
        
        resources.scriptIDs.insert(ClientStateRuntime.scriptID)
        resources.scripts.append(
            ScriptResource(
                id: ClientStateRuntime.scriptID,
                scope: .global,
                content: ClientStateRuntime.script
            )
        )
    }

    func renderedResources() -> RenderedResources {
        let css = resources.styleRegistry.renderCSS()
        let styles = css.isEmpty ? [] : [
            StyleResource(id: "swiftwebui-styles", scope: .global, content: css)
        ]
        return RenderedResources(styles: styles, scripts: resources.scripts)
    }
}

extension RenderContext {
    mutating func elementAttributes(
        _ baseAttributes: [SwiftHTML.Attribute] = [],
        css baseCSS: [any CSSProperty] = []
    ) -> ElementAttributes {
        var cssProperties = baseCSS
        var classNames: [String] = []
        var id: String?
        var attributes: [SwiftHTML.Attribute] = []

        for attribute in baseAttributes {
            switch attribute.key {
            case "class":
                classNames.append(attribute.value)
            case "id":
                id = attribute.value
            default:
                attributes.append(attribute)
            }
        }

        let expandedModifiers = modifiers.flatMap { modifier -> [ViewModifierData] in
            switch modifier {
            case .buttonStyle(let style):
                style.modifiers()
            default:
                [modifier]
            }
        }

        for modifier in expandedModifiers {
            switch modifier {
            case .cssClass(let name):
                classNames.append(name)
            case .id(let value):
                id = value
            case .attribute(let attribute):
                switch attribute.key {
                case "class":
                    classNames.append(attribute.value)
                case "id":
                    id = attribute.value
                default:
                    attributes.append(attribute)
                }
            case .display(let value):
                cssProperties.append(Display(value))
            case .margin(let edges, let value):
                cssProperties.append(contentsOf: marginProperties(edges, value))
            case .padding(let edges, let value):
                cssProperties.append(contentsOf: paddingProperties(edges, value))
            case .frame(let width, let height, let maxWidth):
                if let width {
                    cssProperties.append(Width(width))
                }
                if let height {
                    cssProperties.append(Height(height))
                }
                if let maxWidth {
                    cssProperties.append(MaxWidth(maxWidth))
                }
            case .width(let value):
                cssProperties.append(Width(value))
            case .minWidth(let value):
                cssProperties.append(MinWidth(value))
            case .maxWidth(let value):
                cssProperties.append(MaxWidth(value))
            case .height(let value):
                cssProperties.append(Height(value))
            case .minHeight(let value):
                cssProperties.append(MinHeight(value))
            case .maxHeight(let value):
                cssProperties.append(MaxHeight(value))
            case .background(let background):
                if let color = background.color {
                    cssProperties.append(BackgroundColor(color))
                } else {
                    cssProperties.append(RawProperty("background", background.cssValue))
                }
            case .foregroundStyle(let color):
                cssProperties.append(SwiftCSS.Color(color))
            case .fontWeight(let value):
                cssProperties.append(FontWeight(value))
            case .font(let token):
                cssProperties.append(contentsOf: token.cssProperties)
            case .letterSpacing(let value):
                cssProperties.append(LetterSpacing(value))
            case .textTransform(let value):
                cssProperties.append(SwiftCSS.TextTransform(value.cssValue))
            case .lineHeight(let value):
                cssProperties.append(LineHeight(value))
            case .textAlign(let value):
                cssProperties.append(TextAlign(value.cssValue))
            case .textDecoration(let value):
                cssProperties.append(SwiftCSS.TextDecoration(value.cssValue))
            case .cornerRadius(let value):
                cssProperties.append(BorderRadius(value))
            case .clipShape(let shape):
                cssProperties.append(contentsOf: shape.cssProperties)
            case .border(let border):
                cssProperties.append(border)
            case .shadow(let shadow):
                cssProperties.append(shadow)
            case .gap(let value):
                cssProperties.append(Gap(value))
            case .buttonStyleToken(let token):
                if let className = token.className {
                    classNames.append(className)
                }
                cssProperties.append(contentsOf: token.cssProperties)
            case .buttonStyle:
                break
            case .setState(let mutation):
                registerClientStateRuntime()
                attributes.append(.init("data-swiftwebui-action", "set-state"))
                attributes.append(.init("data-swiftwebui-state-key", mutation.key))
                attributes.append(.init("data-swiftwebui-state-value", mutation.value))
            }
        }

        if !cssProperties.isEmpty {
            classNames.append(className(for: cssProperties))
        }

        if !classNames.isEmpty {
            attributes.append(.class(classNames.joined(separator: " ")))
        }
        if let id {
            attributes.append(.id(id))
        }

        return ElementAttributes(htmlAttributes: attributes)
    }

    private func paddingProperties(_ edges: Edge.Set, _ value: SwiftCSS.Length) -> [any CSSProperty] {
        if edges == .all {
            return [Padding(value)]
        }

        var properties: [any CSSProperty] = []
        if edges.contains(.top) {
            properties.append(RawProperty("padding-top", value.rawValue))
        }
        if edges.contains(.leading) {
            properties.append(RawProperty("padding-left", value.rawValue))
        }
        if edges.contains(.bottom) {
            properties.append(RawProperty("padding-bottom", value.rawValue))
        }
        if edges.contains(.trailing) {
            properties.append(RawProperty("padding-right", value.rawValue))
        }
        return properties
    }

    private func marginProperties(_ edges: Edge.Set, _ value: SwiftCSS.Length) -> [any CSSProperty] {
        if edges == .all {
            return [Margin(value)]
        }

        var properties: [any CSSProperty] = []
        if edges.contains(.top) {
            properties.append(MarginTop(value))
        }
        if edges.contains(.leading) {
            properties.append(MarginLeft(value))
        }
        if edges.contains(.bottom) {
            properties.append(MarginBottom(value))
        }
        if edges.contains(.trailing) {
            properties.append(MarginRight(value))
        }
        return properties
    }
}

private extension ClipShape {
    var cssProperties: [any CSSProperty] {
        switch self {
        case .capsule:
            [BorderRadius(.px(999))]
        }
    }
}
