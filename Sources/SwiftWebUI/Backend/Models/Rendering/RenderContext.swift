//
//  ElementAttributes.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftCSS
import SwiftHTML

public struct RenderContext {
    var modifiers: [ViewModifierData]
    private var resources: RenderResourceStorage

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
        var attributes = baseAttributes
        var cssProperties = baseCSS
        var classNames: [String] = []
        var id: String?

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
            case .padding(let edges, let value):
                cssProperties.append(contentsOf: paddingProperties(edges, value))
            case .frame(let width, let height, let maxWidth):
                if let width {
                    cssProperties.append(Width(width.cssLength))
                }
                if let height {
                    cssProperties.append(Height(height.cssLength))
                }
                if let maxWidth {
                    cssProperties.append(MaxWidth(maxWidth.cssLength))
                }
            case .background(let background):
                if let color = background.cssColor {
                    cssProperties.append(BackgroundColor(color))
                } else {
                    cssProperties.append(RawProperty("background", background.cssValue))
                }
            case .foregroundStyle(let color):
                cssProperties.append(SwiftCSS.Color(color.cssColor))
            case .fontWeight(let value):
                cssProperties.append(FontWeight(value))
            case .font(let token):
                cssProperties.append(contentsOf: token.cssProperties)
            case .cornerRadius(let value):
                cssProperties.append(BorderRadius(value.cssLength))
            case .clipShape(let shape):
                cssProperties.append(contentsOf: shape.cssProperties)
            case .border(let border):
                cssProperties.append(border)
            case .shadow(let shadow):
                cssProperties.append(shadow)
            case .gap(let value):
                cssProperties.append(Gap(value.cssLength))
            case .buttonStyleToken(let token):
                if let className = token.className {
                    classNames.append(className)
                }
                cssProperties.append(contentsOf: token.cssProperties)
            case .buttonStyle:
                break
            case .setState(let mutation):
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

    private func paddingProperties(_ edges: Edge.Set, _ value: Length) -> [any CSSProperty] {
        if edges == .all {
            return [Padding(value.cssLength)]
        }

        var properties: [any CSSProperty] = []
        if edges.contains(.top) {
            properties.append(RawProperty("padding-top", value.cssValue))
        }
        if edges.contains(.leading) {
            properties.append(RawProperty("padding-left", value.cssValue))
        }
        if edges.contains(.bottom) {
            properties.append(RawProperty("padding-bottom", value.cssValue))
        }
        if edges.contains(.trailing) {
            properties.append(RawProperty("padding-right", value.cssValue))
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
