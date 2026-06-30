//
//  SwiftHTMLBridge.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftCSS
import SwiftHTML

extension EmptyView: SwiftHTMLRenderable {
    func renderSwiftHTML(context: inout RenderContext) -> [any SwiftHTML.HTMLNode] {
        []
    }
}

extension AnyView: SwiftHTMLRenderable {
    func renderSwiftHTML(context: inout RenderContext) -> [any SwiftHTML.HTMLNode] {
        renderStorage(&context)
    }
}

extension GroupView: SwiftHTMLRenderable {
    func renderSwiftHTML(context: inout RenderContext) -> [any SwiftHTML.HTMLNode] {
        context.renderTransparentContainer { childContext in
            var nodes: [any SwiftHTML.HTMLNode] = []
            for child in children {
                nodes.append(contentsOf: child.renderSwiftHTML(context: &childContext))
            }
            return nodes
        }
    }
}

extension Group: SwiftHTMLRenderable {
    func renderSwiftHTML(context: inout RenderContext) -> [any SwiftHTML.HTMLNode] {
        context.renderTransparentContainer { childContext in
            content.renderSwiftHTML(context: &childContext)
        }
    }
}

extension ModifiedView: SwiftHTMLRenderable {
    func renderSwiftHTML(context: inout RenderContext) -> [any SwiftHTML.HTMLNode] {
        var modifiedContext = context.appending(modifiers)
        return content.renderSwiftHTML(context: &modifiedContext)
    }
}

extension Text: SwiftHTMLRenderable {
    func renderSwiftHTML(context: inout RenderContext) -> [any SwiftHTML.HTMLNode] {
        let attributes = context.elementAttributes()
        switch semanticRole {
        case .span:
            return [
                SwiftHTML.Span(attributes.attributes) {
                    SwiftHTML.TextNode(content)
                }
            ]
        case .p:
            return [
                SwiftHTML.P(attributes.attributes) {
                    SwiftHTML.TextNode(content)
                }
            ]
        case .h1:
            return [
                SwiftHTML.H1(attributes.attributes) {
                    SwiftHTML.TextNode(content)
                }
            ]
        case .h2:
            return [
                SwiftHTML.H2(attributes.attributes) {
                    SwiftHTML.TextNode(content)
                }
            ]
        case .h3:
            return [
                SwiftHTML.H3(attributes.attributes) {
                    SwiftHTML.TextNode(content)
                }
            ]
        case .h4, .h5, .h6:
            preconditionFailure(
                "SwiftHTML must add concrete H4, H5, and H6 nodes before SwiftWebUI can render these semantic roles."
            )
        }
    }
}

extension VStack: SwiftHTMLRenderable {
    func renderSwiftHTML(context: inout RenderContext) -> [any SwiftHTML.HTMLNode] {
        var css: [any CSSProperty] = [
            Display(.flex),
            RawProperty("flex-direction", "column"),
            AlignItems(alignment.alignItemsValue)
        ]
        if let spacing {
            css.append(Gap(spacing))
        }

        let attributes = context.elementAttributes(css: css)
        var childContext = context.clearingModifiers()
        return [
            SwiftHTML.Div(attributes.attributes) {
                content.renderSwiftHTML(context: &childContext)
            }
        ]
    }
}

extension HStack: SwiftHTMLRenderable {
    func renderSwiftHTML(context: inout RenderContext) -> [any SwiftHTML.HTMLNode] {
        var css: [any CSSProperty] = [
            Display(.flex),
            RawProperty("flex-direction", "row"),
            AlignItems(alignment.alignItemsValue)
        ]
        if let spacing {
            css.append(Gap(spacing))
        }

        let attributes = context.elementAttributes(css: css)
        var childContext = context.clearingModifiers()
        return [
            SwiftHTML.Div(attributes.attributes) {
                content.renderSwiftHTML(context: &childContext)
            }
        ]
    }
}

extension Grid: SwiftHTMLRenderable {
    func renderSwiftHTML(context: inout RenderContext) -> [any SwiftHTML.HTMLNode] {
        var css: [any CSSProperty] = [
            Display(.grid)
        ]
        if let spacing {
            css.append(Gap(spacing))
        }

        let attributes = context.elementAttributes(css: css)
        var childContext = context.clearingModifiers()
        return [
            SwiftHTML.Div(attributes.attributes) {
                content.renderSwiftHTML(context: &childContext)
            }
        ]
    }
}

extension Link: SwiftHTMLRenderable {
    func renderSwiftHTML(context: inout RenderContext) -> [any SwiftHTML.HTMLNode] {
        let attributes = context.elementAttributes([.href(destination)])
        return [
            SwiftHTML.A(attributes.attributes) {
                SwiftHTML.TextNode(label)
            }
        ]
    }
}

extension Button: SwiftHTMLRenderable {
    func renderSwiftHTML(context: inout RenderContext) -> [any SwiftHTML.HTMLNode] {
        var baseAttributes: [SwiftHTML.Attribute] = []
        if action != nil {
            baseAttributes.append(.init("data-swiftwebui-action", "closure-placeholder"))
        }

        let attributes = context.elementAttributes(baseAttributes)
        return [
            SwiftHTMLButton(attributes.attributes) {
                SwiftHTML.TextNode(label)
            }
        ]
    }
}

extension Tab: SwiftHTMLRenderable {
    func renderSwiftHTML(context: inout RenderContext) -> [any SwiftHTML.HTMLNode] {
        renderSwiftHTML(context: &context, selected: false)
    }

    func renderSwiftHTML(
        context: inout RenderContext,
        selected: Bool,
        clientState: ClientStateBinding? = nil,
        selectedClass: String? = nil,
        unselectedClass: String? = nil
    ) -> [any SwiftHTML.HTMLNode] {
        var baseAttributes: [SwiftHTML.Attribute] = [
            .init("type", "button"),
            .init("role", "tab"),
            .init("aria-selected", selected ? "true" : "false")
        ]
        
        if let clientState {
            context.registerClientStateRuntime()
            baseAttributes.append(.init("data-swiftwebui-action", "set-state"))
            baseAttributes.append(.init("data-swiftwebui-state-key", clientState.key))
            baseAttributes.append(.init("data-swiftwebui-state-value", clientStateValueString(value)))
            baseAttributes.append(.init("data-swiftwebui-selected", selected ? "true" : "false"))
            if let selectedClass {
                baseAttributes.append(.init("data-swiftwebui-selected-class", selectedClass))
            }
            if let unselectedClass {
                baseAttributes.append(.init("data-swiftwebui-unselected-class", unselectedClass))
            }
        }
        
        var className = selected ? "swiftwebui-tab swiftwebui-tab-selected" : "swiftwebui-tab"
        if let selectedClass, let unselectedClass {
            className += " \(selected ? selectedClass : unselectedClass)"
        }
        baseAttributes.append(.class(className))
        
        let attributes = context.elementAttributes(
            baseAttributes,
            css: selectedClass == nil ? tabCSS(selected: selected) : []
        )
        var childContext = context.clearingModifiers()
        return [
            SwiftHTMLButton(attributes.attributes) {
                label.renderSwiftHTML(context: &childContext)
            }
        ]
    }

    func tabCSS(selected: Bool) -> [any CSSProperty] {
        tabStyleCSS(selected: selected)
    }
}

extension TabBar: SwiftHTMLRenderable {
    func renderSwiftHTML(context: inout RenderContext) -> [any SwiftHTML.HTMLNode] {
        let selectedClass: String?
        let unselectedClass: String?
        if clientState != nil {
            selectedClass = context.className(for: tabStyleCSS(selected: true), scope: .component("Tab"))
            unselectedClass = context.className(for: tabStyleCSS(selected: false), scope: .component("Tab"))
            context.registerClientStateRuntime()
        } else {
            selectedClass = nil
            unselectedClass = nil
        }
        
        var baseAttributes: [SwiftHTML.Attribute] = [
            .init("role", "tablist"),
            .class("swiftwebui-tab-bar")
        ]
        if let clientState {
            baseAttributes.append(.init("data-swiftwebui-state-key", clientState.key))
            baseAttributes.append(.init("data-swiftwebui-state-initial-value", clientState.initialValue))
        }
        
        let attributes = context.elementAttributes(
            baseAttributes,
            css: [
                Display(.flex),
                RawProperty("flex-direction", "row"),
                AlignItems(.center),
                Gap(.px(8))
            ]
        )
        var childContext = context.clearingModifiers()
        return [
            SwiftHTML.Div(attributes.attributes) {
                tabs.flatMap { tab in
                    tab.renderSwiftHTML(
                        context: &childContext,
                        selected: tab.value == selection,
                        clientState: clientState,
                        selectedClass: selectedClass,
                        unselectedClass: unselectedClass
                    )
                }
            }
        ]
    }
}

private func tabStyleCSS(selected: Bool) -> [any CSSProperty] {
    let black = SwiftCSS.Color("#000")
    let white = SwiftCSS.Color("#fff")

    return [
        Display(.inlineFlex),
        AlignItems(.center),
        Gap(.px(6)),
        Padding(.init("0.5rem 0.875rem")),
        BorderRadius(.px(999)),
        Border("1px solid \(black.rawValue)"),
        BackgroundColor(selected ? black : white),
        SwiftCSS.Color(selected ? white : black),
        FontWeight(selected ? "700" : "600")
    ]
}

private extension RenderContext {
    mutating func renderTransparentContainer(
        children: (inout RenderContext) -> [any SwiftHTML.HTMLNode]
    ) -> [any SwiftHTML.HTMLNode] {
        guard hasPendingModifiers else {
            return children(&self)
        }

        let attributes = elementAttributes()
        var childContext = clearingModifiers()
        return [
            SwiftHTML.Div(attributes.attributes) {
                children(&childContext)
            }
        ]
    }
}

extension Section: SwiftHTMLRenderable {
    func renderSwiftHTML(context: inout RenderContext) -> [any SwiftHTML.HTMLNode] {
        let attributes = context.elementAttributes()
        var childContext = context.clearingModifiers()
        return [
            SwiftHTML.Section(attributes.attributes) {
                content.renderSwiftHTML(context: &childContext)
            }
        ]
    }
}

extension Div: SwiftHTMLRenderable {
    func renderSwiftHTML(context: inout RenderContext) -> [any SwiftHTML.HTMLNode] {
        let attributes = context.elementAttributes()
        var childContext = context.clearingModifiers()
        return [
            SwiftHTML.Div(attributes.attributes) {
                content.renderSwiftHTML(context: &childContext)
            }
        ]
    }
}

extension Image: SwiftHTMLRenderable {
    func renderSwiftHTML(context: inout RenderContext) -> [any SwiftHTML.HTMLNode] {
        let attributes = context.elementAttributes([.src(source), .alt(alt)])
        return [SwiftHTMLImage(attributes.attributes)]
    }
}

extension Spacer: SwiftHTMLRenderable {
    func renderSwiftHTML(context: inout RenderContext) -> [any SwiftHTML.HTMLNode] {
        let attributes = context.elementAttributes(
            [.init("aria-hidden", "true")],
            css: [RawProperty("flex", "1 1 auto")]
        )
        return [SwiftHTML.Div(attributes.attributes) {}]
    }
}

extension Alignment {
    var alignItemsValue: AlignItemsValue {
        switch self {
        case .leading, .top:
                .flexStart
        case .center:
                .center
        case .trailing, .bottom:
                .flexEnd
        }
    }
}

// SwiftHTML does not currently ship a button element. This is only an element
// adapter conforming to SwiftHTML protocols, not a separate renderer.
struct SwiftHTMLButton: SwiftHTML.ContainerElement {
    let tag = "button"
    let attributes: [SwiftHTML.Attribute]
    let children: [any SwiftHTML.HTMLNode]

    init(
        _ attributes: [SwiftHTML.Attribute],
        @SwiftHTML.HTMLBuilder children: () -> [any SwiftHTML.HTMLNode]
    ) {
        self.attributes = attributes
        self.children = children()
    }
}

// SwiftHTML's Img currently exposes only a variadic initializer, so dynamic
// modifier attributes need the same thin adapter shape as Button.
struct SwiftHTMLImage: SwiftHTML.VoidElement {
    let tag = "img"
    let attributes: [SwiftHTML.Attribute]

    init(_ attributes: [SwiftHTML.Attribute]) {
        self.attributes = attributes
    }
}
