//
//  WebNodeStaticLowerer.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

import SwiftCSS
import SwiftHTML
@_spi(Rendering) import SwiftWebUI

struct StaticRenderContext {
    var styleRegistry = StyleRegistry()
    var scripts: [ScriptResource] = []
    private var scriptIDs: Set<String> = []

    mutating func className(for declarations: [SwiftCSS.CSSDeclaration]) -> String {
        styleRegistry.className(for: declarations)
    }

    mutating func registerClientStateRuntime() {
        registerScript(id: ClientStateRuntime.scriptID, content: ClientStateRuntime.script)
    }

    mutating func registerRemoteListRuntime() {
        registerScript(id: RemoteListRuntime.scriptID, content: RemoteListRuntime.script)
    }

    func renderedResources() -> RenderedResources {
        let css = styleRegistry.renderCSS()
        let styles = css.isEmpty
            ? []
            : [StyleResource(id: "swiftwebui-styles", scope: .global, content: css)]
        return RenderedResources(styles: styles, scripts: scripts)
    }

    private mutating func registerScript(id: String, content: String) {
        guard scriptIDs.insert(id).inserted else { return }
        scripts.append(.init(id: id, scope: .global, content: content))
    }
}

/// Mechanical SwiftHTML/SwiftCSS backend for an already-semantic ``WebNode`` tree.
struct WebNodeStaticLowerer {
    func lower(
        _ node: WebNode,
        context: inout StaticRenderContext
    ) -> [SwiftHTML.HTMLNode] {
        switch node {
        case .empty:
            return []
        case .text(let content):
            return [.text(content)]
        case .fragment(let children):
            return children.flatMap { lower($0, context: &context) }
        case .element(let webElement):
            let attributes = lowerAttributes(of: webElement, context: &context)
            let children = webElement.children.flatMap { lower($0, context: &context) }
            return [.element(.init(
                tag: webElement.tagName,
                attributes: attributes,
                children: children,
                isVoid: isVoidElement(webElement.tagName)
            ))]
        }
    }

    private func lowerAttributes(
        of element: WebElementNode,
        context: inout StaticRenderContext
    ) -> [SwiftHTML.Attribute] {
        var attributes: [SwiftHTML.Attribute] = []
        var classNames: [String] = []
        var classInsertionIndex: Int?
        var identifier: String?

        for attribute in element.attributes {
            if attribute.name == "class", classInsertionIndex == nil {
                classInsertionIndex = attributes.count
            }
            collect(
                .init(attribute.name, attribute.value),
                attributes: &attributes,
                classNames: &classNames,
                identifier: &identifier
            )
            if attribute.name == "data-swiftwebui-remote-list" {
                context.registerRemoteListRuntime()
            }
        }

        if !element.styles.isEmpty {
            classNames.append(context.className(for: cssDeclarations(element.styles)))
        }
        for variant in element.styleVariants {
            let className = context.className(for: cssDeclarations(variant.styles))
            attributes.append(.init(variant.classAttributeName, className))
        }

        var actionAttributes: [SwiftHTML.Attribute] = []
        switch element.action {
        case .closure:
            actionAttributes.append(.init("data-swiftwebui-action", "closure-placeholder"))
        case .setState(let mutation):
            context.registerClientStateRuntime()
            actionAttributes.append(.init("data-swiftwebui-action", "set-state"))
            actionAttributes.append(.init("data-swiftwebui-state-key", webStateKey(mutation.target)))
            actionAttributes.append(.init("data-swiftwebui-state-value", webClientValueString(mutation.value)))
        case .none:
            break
        }

        if let insertionIndex = classInsertionIndex, !actionAttributes.isEmpty {
            attributes.insert(contentsOf: actionAttributes, at: insertionIndex)
            classInsertionIndex = insertionIndex + actionAttributes.count
        } else {
            attributes.append(contentsOf: actionAttributes)
        }

        if !classNames.isEmpty {
            attributes.insert(
                .init("class", classNames.joined(separator: " ")),
                at: classInsertionIndex ?? attributes.endIndex
            )
        }
        if let identifier { attributes.append(.init("id", identifier)) }
        return attributes
    }

    private func collect(
        _ attribute: SwiftHTML.Attribute,
        attributes: inout [SwiftHTML.Attribute],
        classNames: inout [String],
        identifier: inout String?
    ) {
        switch attribute.key {
        case "class": classNames.append(attribute.value)
        case "id": identifier = attribute.value
        default: attributes.append(attribute)
        }
    }

    private func cssDeclarations(
        _ styles: [WebStyleDeclaration]
    ) -> [SwiftCSS.CSSDeclaration] {
        styles.map { RawProperty($0.name, $0.value).cssDeclaration }
    }

    private func isVoidElement(_ tagName: String) -> Bool {
        switch tagName {
        case "area", "base", "br", "col", "embed", "hr", "img", "input", "link", "meta", "source", "track", "wbr":
            true
        default:
            false
        }
    }
}
