//
//  ViewNodeToWebNodeLowerer.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

import SwiftCSS

/// The single semantic lowering boundary shared by static and runtime renderers.
@_spi(Rendering)
public struct ViewNodeToWebNodeLowerer {
    public init() {}

    public func lower(_ node: ViewNode) -> WebNode {
        lower(node, modifiers: [])
    }

    private func lower(_ node: ViewNode, modifiers: [ViewModifierNode]) -> WebNode {
        switch node {
        case .empty:
            return .empty
        case .text(let text):
            return element(
                tagName: tagName(for: text.semanticRole),
                modifiers: modifiers,
                children: [.text(text.content)]
            )
        case .container(let container):
            return lower(container, modifiers: modifiers)
        case .button(let button):
            return element(
                tagName: "button",
                modifiers: modifiers,
                children: plainTextOrLowered(button.label),
                action: button.action
            )
        case .link(let link):
            return element(
                tagName: "a",
                baseAttributes: [.init(name: "href", value: link.destination)],
                modifiers: modifiers,
                children: link.usesPlainTextLabel
                    ? plainTextOrLowered(link.label)
                    : flattenedChildren(of: lower(link.label))
            )
        case .image(let image):
            return element(
                tagName: "img",
                baseAttributes: [
                    .init(name: "src", value: image.source),
                    .init(name: "alt", value: image.alternativeText),
                ],
                modifiers: modifiers
            )
        case .input:
            return element(tagName: "input", modifiers: modifiers)
        case .textArea:
            return element(tagName: "textarea", modifiers: modifiers)
        case .spacer:
            return element(
                tagName: "div",
                baseAttributes: [.init(name: "aria-hidden", value: "true")],
                baseStyles: [.init(name: "flex", value: "1 1 auto")],
                modifiers: modifiers
            )
        case .tabControl(let control):
            return lower(control, modifiers: modifiers)
        case .group(let children):
            return lowerGroup(children, modifiers: modifiers)
        case .modified(let modified):
            return lower(modified.content, modifiers: modified.modifiers + modifiers)
        }
    }

    private func lower(_ container: ContainerNode, modifiers: [ViewModifierNode]) -> WebNode {
        if case .group = container.kind {
            return lowerGroup(container.children, modifiers: modifiers)
        }

        let tagName: String
        var attributes: [WebAttribute] = []
        var styles: [WebStyleDeclaration] = []
        var children: [WebNode] = []
        var sharesOneGridCell = false
        var presentation: DialogPresentation?
        var dismissAction: ActionIntent?

        switch container.kind {
        case .group:
            return lowerGroup(container.children, modifiers: modifiers)
        case .vertical(let alignment, let spacing):
            tagName = "div"
            styles = stackStyles(direction: "column", alignment: alignment, spacing: spacing)
        case .horizontal(let alignment, let spacing):
            tagName = "div"
            styles = stackStyles(direction: "row", alignment: alignment, spacing: spacing)
        case .grid(let spacing):
            tagName = "div"
            styles = [style(Display(.grid).cssDeclaration)]
            if let spacing { styles.append(style(Gap(spacing).cssDeclaration)) }
        case .layered(let alignment):
            tagName = "div"
            styles = layeredStyles(alignment: alignment)
            sharesOneGridCell = true
        case .dialog(let dialogPresentation, let onDismiss):
            tagName = "dialog"
            presentation = dialogPresentation
            dismissAction = onDismiss
            // A key handler only fires while focus is inside its element, and a
            // dialog is not focusable by default.
            attributes.append(.init(name: "tabindex", value: "-1"))
            attributes.append(.init(name: "class", value: dialogBackdropClassName))
        case .div:
            tagName = "div"
        case .article:
            tagName = "article"
        case .section:
            tagName = "section"
        case .form:
            tagName = "form"
        case .label(let text):
            tagName = "label"
            if let text { children.append(.text(text)) }
        case .footer:
            tagName = "footer"
        case .template(let name):
            tagName = "template"
            attributes.append(.init(name: "data-swiftwebui-template", value: name))
        case .element(let tag):
            // Verbatim, casing included: the foreign elements this exists for
            // (`viewBox` on `svg`, `clipPath`) are the ones that care.
            tagName = tag
        }

        let loweredChildren = container.children.flatMap { flattenedChildren(of: lower($0)) }
        children.append(contentsOf: sharesOneGridCell ? loweredChildren.map(inOneGridCell) : loweredChildren)
        return element(
            tagName: tagName,
            baseAttributes: attributes,
            baseStyles: styles,
            modifiers: modifiers,
            children: children,
            presentation: presentation,
            dismissAction: dismissAction
        )
    }

    private func lowerGroup(_ children: [ViewNode], modifiers: [ViewModifierNode]) -> WebNode {
        let lowered = children.flatMap { flattenedChildren(of: lower($0)) }
        guard !modifiers.isEmpty else { return .fragment(lowered) }
        return element(tagName: "div", modifiers: modifiers, children: lowered)
    }

    private func lower(_ control: TabControlNode, modifiers: [ViewModifierNode]) -> WebNode {
        let stateKey = control.state.map { webStateKey($0.target) }
        var wrapperAttributes = [
            WebAttribute(
                name: control.kind == .bar ? "data-swiftwebui-tab-bar" : "data-swiftwebui-tab-view",
                value: "true"
            ),
            WebAttribute(
                name: "class",
                value: control.kind == .bar ? "swiftwebui-tab-bar" : "swiftwebui-tab-view"
            ),
        ]
        if let stateKey, let state = control.state {
            wrapperAttributes.append(.init(name: "data-swiftwebui-state-key", value: stateKey))
            wrapperAttributes.append(.init(
                name: "data-swiftwebui-state-initial-value",
                value: webClientValueString(state.initialValue)
            ))
        }

        let wrapperStyles: [WebStyleDeclaration]
        switch control.kind {
        case .bar:
            wrapperStyles = stackStyles(direction: "row", alignment: .center, spacing: nil)
        case .view:
            wrapperStyles = stackStyles(direction: "column", alignment: .center, spacing: .px(12))
        }

        var tabListAttributes = [
            WebAttribute(name: "role", value: "tablist"),
            WebAttribute(name: "class", value: "swiftwebui-tab-list"),
        ]
        if let stateKey, let state = control.state {
            tabListAttributes.append(.init(name: "data-swiftwebui-state-key", value: stateKey))
            tabListAttributes.append(.init(
                name: "data-swiftwebui-state-initial-value",
                value: webClientValueString(state.initialValue)
            ))
        }

        let selectedStyles = tabStyles(selected: true)
        let unselectedStyles = tabStyles(selected: false)
        let tabButtons = control.tabs.map { tab in
            let selected = tab.value == control.selection
            var attributes = [
                WebAttribute(name: "type", value: "button"),
                WebAttribute(name: "role", value: "tab"),
                WebAttribute(name: "aria-selected", value: selected ? "true" : "false"),
            ]
            var action: ActionIntent?
            var variants: [WebStyleVariant] = []
            if let state = control.state {
                attributes.append(.init(name: "data-swiftwebui-selected", value: selected ? "true" : "false"))
                action = .setState(.init(target: state.target, value: tab.value))
                variants = [
                    .init(classAttributeName: "data-swiftwebui-selected-class", styles: selectedStyles),
                    .init(classAttributeName: "data-swiftwebui-unselected-class", styles: unselectedStyles),
                ]
            }
            attributes.append(.init(
                name: "class",
                value: selected ? "swiftwebui-tab swiftwebui-tab-selected" : "swiftwebui-tab"
            ))
            return WebNode.element(.init(
                tagName: "button",
                attributes: attributes,
                styles: selected ? selectedStyles : unselectedStyles,
                styleVariants: variants,
                children: flattenedChildren(of: lower(tab.label)),
                action: action
            ))
        }

        var children: [WebNode] = [
            .element(.init(
                tagName: "div",
                attributes: tabListAttributes,
                styles: stackStyles(direction: "row", alignment: .center, spacing: .px(8)),
                children: tabButtons
            ))
        ]
        if control.kind == .view {
            children.append(contentsOf: control.tabs.map { tab in
                let selected = tab.value == control.selection
                var attributes = [
                    WebAttribute(name: "role", value: "tabpanel"),
                    WebAttribute(name: "class", value: "swiftwebui-tab-panel"),
                ]
                if !selected { attributes.append(.init(name: "hidden", value: "hidden")) }
                if let stateKey {
                    attributes.append(.init(name: "data-swiftwebui-state-panel-key", value: stateKey))
                    attributes.append(.init(
                        name: "data-swiftwebui-state-panel-value",
                        value: webClientValueString(tab.value)
                    ))
                }
                return .element(.init(
                    tagName: "div",
                    attributes: attributes,
                    children: flattenedChildren(of: lower(tab.content))
                ))
            })
        }

        return element(
            tagName: "div",
            baseAttributes: wrapperAttributes,
            baseStyles: wrapperStyles,
            modifiers: modifiers,
            children: children
        )
    }

    private func element(
        tagName: String,
        baseAttributes: [WebAttribute] = [],
        baseStyles: [WebStyleDeclaration] = [],
        modifiers: [ViewModifierNode],
        children: [WebNode] = [],
        action baseAction: ActionIntent? = nil,
        presentation: DialogPresentation? = nil,
        dismissAction: ActionIntent? = nil
    ) -> WebNode {
        var attributes: [WebAttribute] = []
        var classNames: [String] = []
        var identifier: String?
        var styles = baseStyles
        var action = baseAction
        var requestsFocus = false
        var keyActions: [KeyAction] = []
        var transitionPhases: TransitionPhases?

        for attribute in baseAttributes {
            collect(attribute, attributes: &attributes, classNames: &classNames, identifier: &identifier)
        }

        for modifier in modifiers {
            switch modifier {
            case .cssClass(let name): classNames.append(name)
            case .identifier(let value): identifier = value
            case .attribute(let name, let value):
                collect(.init(name: name, value: value), attributes: &attributes, classNames: &classNames, identifier: &identifier)
            case .bindText(let field): attributes.append(.init(name: "data-swiftwebui-bind-text", value: field))
            case .bindAttribute(let name, let field): attributes.append(.init(name: "data-swiftwebui-bind-attribute-\(name)", value: field))
            case .display(let value): styles.append(style(Display(value).cssDeclaration))
            case .gridTemplateColumns(let value): styles.append(style(GridTemplateColumns(value).cssDeclaration))
            case .justifyContent(let value): styles.append(style(JustifyContent(value).cssDeclaration))
            case .flexWrap(let value): styles.append(style(FlexWrap(value).cssDeclaration))
            case .alignItems(let value): styles.append(style(AlignItems(value).cssDeclaration))
            case .alignSelf(let value): styles.append(style(AlignSelf(value).cssDeclaration))
            case .flexGrow(let value): styles.append(style(FlexGrow(value).cssDeclaration))
            case .flexShrink(let value): styles.append(style(FlexShrink(value).cssDeclaration))
            case .flexBasis(let value): styles.append(style(FlexBasis(value).cssDeclaration))
            case .margin(let edges, let value): styles.append(contentsOf: edgeStyles(prefix: "margin", edges: edges, value: value))
            case .padding(let edges, let value): styles.append(contentsOf: edgeStyles(prefix: "padding", edges: edges, value: value))
            case .frame(let width, let height, let maxWidth):
                if let width { styles.append(style(Width(width).cssDeclaration)) }
                if let height { styles.append(style(Height(height).cssDeclaration)) }
                if let maxWidth { styles.append(style(MaxWidth(maxWidth).cssDeclaration)) }
            case .width(let value): styles.append(style(Width(value).cssDeclaration))
            case .minWidth(let value): styles.append(style(MinWidth(value).cssDeclaration))
            case .maxWidth(let value): styles.append(style(MaxWidth(value).cssDeclaration))
            case .height(let value): styles.append(style(Height(value).cssDeclaration))
            case .minHeight(let value): styles.append(style(MinHeight(value).cssDeclaration))
            case .maxHeight(let value): styles.append(style(MaxHeight(value).cssDeclaration))
            case .background(let background):
                styles.append(background.color.map { .init(name: "background-color", value: $0.rawValue) }
                    ?? .init(name: "background", value: background.rawCSSValue))
            case .foregroundStyle(let value): styles.append(.init(name: "color", value: value.rawValue))
            case .fontWeight(let value): styles.append(style(FontWeight(value).cssDeclaration))
            case .font(let value): styles.append(contentsOf: fontStyles(value))
            case .letterSpacing(let value): styles.append(style(LetterSpacing(value).cssDeclaration))
            case .textTransform(let value): styles.append(.init(name: "text-transform", value: textTransformValue(value)))
            case .wordBreak(let value): styles.append(style(WordBreak(value).cssDeclaration))
            case .lineHeight(let value): styles.append(.init(name: "line-height", value: value.rawValue))
            case .textAlign(let value): styles.append(.init(name: "text-align", value: textAlignmentValue(value)))
            case .textDecoration(let value): styles.append(.init(name: "text-decoration", value: textDecorationValue(value)))
            case .opacity(let value): styles.append(style(Opacity(value).cssDeclaration))
            case .transform(let value): styles.append(style(Transform(value).cssDeclaration))
            case .transition(let value): styles.append(style(Transition(value).cssDeclaration))
            case .backdropFilter(let value): styles.append(style(BackdropFilter(value).cssDeclaration))
            case .overflow(let value): styles.append(style(Overflow(value).cssDeclaration))
            case .objectFit(let value): styles.append(style(ObjectFit(value).cssDeclaration))
            case .aspectRatio(let value): styles.append(style(value.cssDeclaration))
            case .objectPosition(let value): styles.append(style(value.cssDeclaration))
            case .pointerEvents(let value): styles.append(style(PointerEvents(value).cssDeclaration))
            case .cursor(let value): styles.append(style(Cursor(value).cssDeclaration))
            case .position(let value): styles.append(style(Position(value).cssDeclaration))
            case .top(let value): styles.append(style(Top(value).cssDeclaration))
            case .right(let value): styles.append(style(Right(value).cssDeclaration))
            case .bottom(let value): styles.append(style(Bottom(value).cssDeclaration))
            case .left(let value): styles.append(style(Left(value).cssDeclaration))
            case .inset(let edges, let value): styles.append(contentsOf: insetStyles(edges: edges, value: value))
            case .zIndex(let value): styles.append(style(ZIndex(value).cssDeclaration))
            case .resize(let value): styles.append(style(Resize(value).cssDeclaration))
            case .outline(let value): styles.append(style(Outline(value).cssDeclaration))
            case .scrollMarginTop(let value): styles.append(style(ScrollMarginTop(value).cssDeclaration))
            case .cornerRadius(let value): styles.append(style(BorderRadius(value).cssDeclaration))
            case .clipShape(.capsule): styles.append(style(BorderRadius(.px(999)).cssDeclaration))
            case .border(let value): styles.append(style(value.cssDeclaration))
            case .borderParts(let width, let lineStyle, let color):
                styles.append(.init(name: "border", value: "\(width.rawValue) \(lineStyle.rawValue) \(color.rawValue)"))
            case .borderEdges(let edges, let value): styles.append(contentsOf: borderEdgeStyles(edges: edges, value: value))
            case .shadow(let value): styles.append(style(value.cssDeclaration))
            case .gap(let value): styles.append(style(Gap(value).cssDeclaration))
            case .buttonStyle(let token):
                if let className = token.className { classNames.append(className) }
                styles.append(contentsOf: token.declarations.map(style))
            case .setState(let mutation): action = .setState(mutation)
            case .defaultFocus: requestsFocus = true
            case .onKeyDown(let key, let keyAction): keyActions.append(.init(key: key, action: keyAction))
            case .transitionPhases(let phases): transitionPhases = phases
            }
        }

        if !classNames.isEmpty { attributes.append(.init(name: "class", value: classNames.joined(separator: " "))) }
        if let identifier { attributes.append(.init(name: "id", value: identifier)) }
        return .element(.init(
            tagName: tagName,
            attributes: attributes,
            styles: styles,
            children: children,
            action: action,
            requestsFocus: requestsFocus,
            keyActions: keyActions,
            presentation: presentation,
            dismissAction: dismissAction,
            transitionPhases: transitionPhases
        ))
    }

    private func collect(
        _ attribute: WebAttribute,
        attributes: inout [WebAttribute],
        classNames: inout [String],
        identifier: inout String?
    ) {
        switch attribute.name {
        case "class": classNames.append(attribute.value)
        case "id": identifier = attribute.value
        default: attributes.append(attribute)
        }
    }

    private func stackStyles(
        direction: String,
        alignment: Alignment,
        spacing: SwiftCSS.Length?
    ) -> [WebStyleDeclaration] {
        var styles = [
            style(Display(.flex).cssDeclaration),
            WebStyleDeclaration(name: "flex-direction", value: direction),
            WebStyleDeclaration(name: "align-items", value: alignmentValue(alignment)),
        ]
        if let spacing { styles.append(style(Gap(spacing).cssDeclaration)) }
        return styles
    }

    /// Lowers ``ContainerKind/layered(alignment:)``.
    ///
    /// A grid, not absolute positioning: absolutely-positioned children are out
    /// of flow, so the stack would collapse to zero height instead of sizing to
    /// its largest child.
    private func layeredStyles(alignment: Alignment) -> [WebStyleDeclaration] {
        [
            style(Display(.grid).cssDeclaration),
            .init(name: "align-items", value: layeredBlockAlignment(alignment)),
            .init(name: "justify-items", value: layeredInlineAlignment(alignment)),
        ]
    }

    /// Wraps a layered child so it shares the single grid cell with its siblings.
    ///
    /// The lowerer builds children generically, so the declaration cannot be
    /// merged into the child itself. The extra element is visible in the output.
    private func inOneGridCell(_ child: WebNode) -> WebNode {
        .element(.init(
            tagName: "div",
            styles: [.init(name: "grid-area", value: "1 / 1")],
            children: [child]
        ))
    }

    private func borderEdgeStyles(edges: Edge.Set, value: String) -> [WebStyleDeclaration] {
        if edges == .all { return [style(SwiftCSS.Border(value).cssDeclaration)] }
        var styles: [WebStyleDeclaration] = []
        if edges.contains(.top) { styles.append(style(BorderTop(value).cssDeclaration)) }
        if edges.contains(.leading) { styles.append(style(BorderLeft(value).cssDeclaration)) }
        if edges.contains(.bottom) { styles.append(style(BorderBottom(value).cssDeclaration)) }
        if edges.contains(.trailing) { styles.append(style(BorderRight(value).cssDeclaration)) }
        return styles
    }

    /// Lowers `.inset(_:_:)`.
    ///
    /// `.all` collapses to the `inset` shorthand. Anything narrower expands to the
    /// individual physical properties, because CSS has no `inset-top` — which is why
    /// this cannot reuse ``edgeStyles(prefix:edges:value:)``.
    private func insetStyles(edges: Edge.Set, value: SwiftCSS.Length) -> [WebStyleDeclaration] {
        if edges == .all { return [style(Inset(value).cssDeclaration)] }
        var styles: [WebStyleDeclaration] = []
        if edges.contains(.top) { styles.append(style(Top(value).cssDeclaration)) }
        if edges.contains(.leading) { styles.append(style(Left(value).cssDeclaration)) }
        if edges.contains(.bottom) { styles.append(style(Bottom(value).cssDeclaration)) }
        if edges.contains(.trailing) { styles.append(style(Right(value).cssDeclaration)) }
        return styles
    }

    private func edgeStyles(
        prefix: String,
        edges: Edge.Set,
        value: SwiftCSS.Length
    ) -> [WebStyleDeclaration] {
        if edges == .all { return [.init(name: prefix, value: value.rawValue)] }
        var styles: [WebStyleDeclaration] = []
        if edges.contains(.top) { styles.append(.init(name: "\(prefix)-top", value: value.rawValue)) }
        if edges.contains(.leading) { styles.append(.init(name: "\(prefix)-left", value: value.rawValue)) }
        if edges.contains(.bottom) { styles.append(.init(name: "\(prefix)-bottom", value: value.rawValue)) }
        if edges.contains(.trailing) { styles.append(.init(name: "\(prefix)-right", value: value.rawValue)) }
        return styles
    }

    private func fontStyles(_ font: Font) -> [WebStyleDeclaration] {
        var styles = [WebStyleDeclaration(name: "font-size", value: "\(formatNumber(font.size))px")]
        if let weight = font.weight { styles.append(.init(name: "font-weight", value: String(weight.numericValue))) }
        if let family = font.design.flatMap(fontFamily) { styles.append(.init(name: "font-family", value: family)) }
        return styles
    }

    private func tabStyles(selected: Bool) -> [WebStyleDeclaration] {
        [
            .init(name: "display", value: "inline-flex"),
            .init(name: "align-items", value: "center"),
            .init(name: "gap", value: "6px"),
            .init(name: "padding", value: "0.5rem 0.875rem"),
            .init(name: "border-radius", value: "999px"),
            .init(name: "border", value: "1px solid #000"),
            .init(name: "background-color", value: selected ? "#000" : "#fff"),
            .init(name: "color", value: selected ? "#fff" : "#000"),
            .init(name: "font-weight", value: selected ? "700" : "600"),
        ]
    }

    private func style(_ declaration: SwiftCSS.CSSDeclaration) -> WebStyleDeclaration {
        switch declaration {
        case .property(let node): .init(name: node.property, value: node.value)
        case .raw(let node): .init(name: node.property, value: node.value)
        }
    }

    private func plainTextOrLowered(_ node: ViewNode) -> [WebNode] {
        if case .text(let text) = node { return [.text(text.content)] }
        return flattenedChildren(of: lower(node))
    }

    private func flattenedChildren(of node: WebNode) -> [WebNode] {
        switch node {
        case .empty: []
        case .fragment(let children): children
        default: [node]
        }
    }
}

private func tagName(for role: SemanticRole) -> String {
    switch role {
    case .span: "span"
    case .p: "p"
    case .h1: "h1"
    case .h2: "h2"
    case .h3: "h3"
    case .h4: "h4"
    case .h5: "h5"
    case .h6: "h6"
    }
}

/// The block-axis half of a layered stack's alignment.
///
/// ``Alignment`` names one axis at a time, so the axis it does not name centres.
private func layeredBlockAlignment(_ alignment: Alignment) -> String {
    switch alignment {
    case .top: "start"
    case .bottom: "end"
    case .leading, .center, .trailing: "center"
    }
}

/// The inline-axis half of a layered stack's alignment.
private func layeredInlineAlignment(_ alignment: Alignment) -> String {
    switch alignment {
    case .leading: "start"
    case .trailing: "end"
    case .top, .center, .bottom: "center"
    }
}

private func alignmentValue(_ alignment: Alignment) -> String {
    switch alignment {
    case .leading, .top: "flex-start"
    case .center: "center"
    case .trailing, .bottom: "flex-end"
    }
}

private func textTransformValue(_ value: TextTransform) -> String {
    switch value {
    case .none: "none"
    case .uppercase: "uppercase"
    case .lowercase: "lowercase"
    case .capitalize: "capitalize"
    }
}

private func textAlignmentValue(_ value: TextAlignment) -> String {
    switch value {
    case .leading: "left"
    case .center: "center"
    case .trailing: "right"
    case .justified: "justify"
    }
}

private func textDecorationValue(_ value: TextDecoration) -> String {
    switch value {
    case .none: "none"
    case .underline: "underline"
    case .lineThrough: "line-through"
    case .overline: "overline"
    }
}

private func fontFamily(_ design: Font.Design) -> String? {
    switch design {
    case .default: nil
    case .serif: "ui-serif, Georgia, Cambria, \"Times New Roman\", Times, serif"
    case .rounded: "ui-rounded, \"SF Pro Rounded\", \"Nunito Sans\", system-ui, sans-serif"
    case .monospaced: "ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, \"Liberation Mono\", monospace"
    }
}

private func formatNumber(_ value: Double) -> String {
    value.rounded() == value ? String(Int(value)) : String(value)
}
