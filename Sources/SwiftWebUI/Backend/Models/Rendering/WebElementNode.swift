//
//  WebElementNode.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

/// A concrete web element whose SwiftWebUI semantics have already been lowered.
///
/// `attributes` and `styles` are normalized on construction so that each name appears once,
/// carrying the last declared value. Every backend therefore renders the same element.
@_spi(Rendering)
public struct WebElementNode: @unchecked Sendable {
    public let tagName: String
    public let attributes: [WebAttribute]
    public let styles: [WebStyleDeclaration]
    public let styleVariants: [WebStyleVariant]
    public let children: [WebNode]
    public let action: ActionIntent?

    public init(
        tagName: String,
        attributes: [WebAttribute] = [],
        styles: [WebStyleDeclaration] = [],
        styleVariants: [WebStyleVariant] = [],
        children: [WebNode] = [],
        action: ActionIntent? = nil
    ) {
        self.tagName = tagName
        self.attributes = attributes.lastDeclarationPerName()
        self.styles = styles.lastDeclarationPerName()
        self.styleVariants = styleVariants
        self.children = children
        self.action = action
    }
}
