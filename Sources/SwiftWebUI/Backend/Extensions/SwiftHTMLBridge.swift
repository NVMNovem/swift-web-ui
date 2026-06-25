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
        children.flatMap { $0.renderSwiftHTML(context: &context) }
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
        return [
            SwiftHTML.Span(attributes.attributes) {
                SwiftHTML.TextNode(content)
            }
        ]
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
            css.append(Gap(spacing.cssLength))
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
            css.append(Gap(spacing.cssLength))
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
