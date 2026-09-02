//
//  SharedWebNodeLowererTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

import Testing
@_spi(Rendering) import SwiftWebUI

@Test func sharedLowererHandlesEmptyTextAndGroup() {
    let lowerer = ViewNodeToWebNodeLowerer()
    guard case .empty = lowerer.lower(EmptyView().makeViewNode()) else {
        Issue.record("Expected empty WebNode")
        return
    }

    let text = requireElement(lowerer.lower(Text("Hello", semanticRole: .h2).makeViewNode()))
    #expect(text?.tagName == "h2")
    #expect(text?.children.count == 1)

    let group = lowerer.lower(Group { Text("One"); Text("Two") }.makeViewNode())
    guard case .fragment(let children) = group else {
        Issue.record("Expected a group fragment")
        return
    }
    #expect(children.count == 2)
}

@Test func sharedLowererCollectsNavigationTitleOutsideTheBodyWebNode() {
    let lowerer = ViewNodeToWebNodeLowerer()
    let lowered = lowerer.lowerView(
        VStack {
            Text("First").navigationTitle("First title")
            Text("Last").navigationTitle("Last title")
        }
        .navigationTitle("Page title")
        .makeViewNode()
    )

    #expect(lowered.documentMetadata.navigationTitle == "Page title")
    let element = requireElement(lowered.webNode)
    #expect(element?.attributes.allSatisfy { !$0.name.contains("title") } == true)
}

@Test func sharedLowererUsesTheLastSiblingNavigationTitleWithoutAContainerTitle() {
    let lowered = ViewNodeToWebNodeLowerer().lowerView(
        Group {
            Text("First").navigationTitle("First title")
            Text("Last").navigationTitle("Last title")
        }
        .makeViewNode()
    )

    #expect(lowered.documentMetadata.navigationTitle == "Last title")
}

@Test func sharedLowererCollectsNavigationIconOutsideTheBodyWebNode() {
    let lowerer = ViewNodeToWebNodeLowerer()
    let lowered = lowerer.lowerView(
        VStack {
            Text("First").navigationIcon(.url("/first.png"))
            Text("Last").navigationIcon(.url("/last.png"))
        }
        .navigationIcon(.svg("<svg viewBox=\"0 0 16 16\"/>"))
        .makeViewNode()
    )

    #expect(lowered.documentMetadata.navigationIcon == .svg("<svg viewBox=\"0 0 16 16\"/>"))
    let element = requireElement(lowered.webNode)
    #expect(element?.attributes.allSatisfy { !$0.name.contains("icon") } == true)
}

@Test func sharedLowererUsesTheLastSiblingNavigationIconWithoutAContainerIcon() {
    let lowered = ViewNodeToWebNodeLowerer().lowerView(
        Group {
            Text("First").navigationIcon(.url("/first.png"))
            Text("Last").navigationIcon(.svg("<svg/>"))
        }
        .makeViewNode()
    )

    #expect(lowered.documentMetadata.navigationIcon == .svg("<svg/>"))
}

@Test func sharedLowererOwnsStackGridAndSemanticContainerMeaning() {
    let vertical = requireElement(lower(VStack(alignment: .leading, spacing: .px(8)) { Text("V") }))
    #expect(vertical?.tagName == "div")
    #expect(vertical?.styles == [
        .init(name: "display", value: "flex"),
        .init(name: "flex-direction", value: "column"),
        .init(name: "align-items", value: "flex-start"),
        .init(name: "gap", value: "8px"),
    ])

    let horizontal = requireElement(lower(HStack { Text("H") }))
    #expect(horizontal?.styles.contains(.init(name: "flex-direction", value: "row")) == true)

    let grid = requireElement(lower(Grid(spacing: .px(6)) { Text("G") }))
    #expect(grid?.styles == [
        .init(name: "display", value: "grid"),
        .init(name: "gap", value: "6px"),
    ])

    #expect(requireElement(lower(Article { Text("A") }))?.tagName == "article")
    #expect(requireElement(lower(Section { Text("S") }))?.tagName == "section")
    #expect(requireElement(lower(Form { Text("F") }))?.tagName == "form")
    #expect(requireElement(lower(Footer { Text("F") }))?.tagName == "footer")
    #expect(requireElement(lower(Label("Name")))?.tagName == "label")
    #expect(requireElement(lower(Template("card") { Text("T") }))?.tagName == "template")
}

@Test func sharedLowererOwnsPrimitiveElementSemantics() {
    let button = requireElement(lower(Button("Go") {}))
    #expect(button?.tagName == "button")
    #expect(button?.children.count == 1)
    #expect(button?.action != nil)

    let link = requireElement(lower(Link("Docs", destination: "/docs")))
    #expect(link?.tagName == "a")
    #expect(link?.attributes == [.init(name: "href", value: "/docs")])

    let image = requireElement(lower(Image("/logo.svg", alt: "Logo")))
    #expect(image?.tagName == "img")
    #expect(image?.attributes == [
        .init(name: "src", value: "/logo.svg"),
        .init(name: "alt", value: "Logo"),
    ])
    #expect(requireElement(lower(Input()))?.tagName == "input")
    #expect(requireElement(lower(TextArea()))?.tagName == "textarea")
}

@Test func sharedLowererCentralizesFontTokensAndModifierDeclarations() {
    let title = requireElement(lower(Text("Title").font(.title)))
    #expect(title?.styles == [
        .init(name: "font-size", value: "28px"),
        .init(name: "font-weight", value: "400"),
    ])

    let caption = requireElement(lower(Text("Caption").font(.caption)))
    #expect(caption?.styles == [
        .init(name: "font-size", value: "12px"),
        .init(name: "font-weight", value: "400"),
    ])

    let styled = requireElement(lower(
        Text("Styled")
            .padding(.horizontal, .px(8))
            .margin(.top, .px(4))
            .opacity(0.5)
            .position(.absolute)
            .top(.px(2))
    ))
    #expect(styled?.styles == [
        .init(name: "padding-left", value: "8px"),
        .init(name: "padding-right", value: "8px"),
        .init(name: "margin-top", value: "4px"),
        .init(name: "opacity", value: "0.5"),
        .init(name: "position", value: "absolute"),
        .init(name: "top", value: "2px"),
    ])
}

@Test func sharedLowererPreservesCanonicalLineHeightValues() {
    let values: [(LineHeightValue, String)] = [
        (.normal, "normal"),
        (.multiple(1.7), "1.7"),
        (.length(.px(28)), "28px"),
        (.percent(170), "170%"),
    ]

    for (value, expected) in values {
        let text = requireElement(lower(Text("Paragraph").lineHeight(value)))
        #expect(text?.styles == [.init(name: "line-height", value: expected)])
    }
}

@Test func sharedLowererPreservesModifierAndChildOrderAndCanonicalAttributes() {
    let node = requireElement(lower(
        VStack {
            Text("First")
            Text("Second")
        }
        .padding(.px(4))
        .padding(.px(8))
        .class("panel")
        .id("main")
        .attribute("data-kind", "sample")
    ))

    #expect(node?.styles.suffix(1) == [.init(name: "padding", value: "8px")])
    #expect(node?.attributes == [
        .init(name: "data-kind", value: "sample"),
        .init(name: "class", value: "panel"),
        .init(name: "id", value: "main"),
    ])
    #expect(node?.children.count == 2)
}

@Test func sharedLowererCollapsesRedeclaredPropertiesToTheLastDeclaration() {
    let button = requireElement(lower(
        Button("Go") {}
            .buttonStyle(.primary)
            .background(Color("var(--accent)"))
    ))
    #expect(button?.styles.filter { $0.name == "background-color" } == [
        .init(name: "background-color", value: "var(--accent)")
    ])
    // Declarations the override does not touch keep their token order.
    #expect(button?.styles.first == .init(name: "display", value: "inline-flex"))

    let text = requireElement(lower(Text("Bold").font(.callout).bold()))
    #expect(text?.styles == [
        .init(name: "font-size", value: "16px"),
        .init(name: "font-weight", value: "bold"),
    ])

    let overridden = requireElement(lower(
        Text("Attr").attribute("data-kind", "first").attribute("data-kind", "last")
    ))
    #expect(overridden?.attributes == [.init(name: "data-kind", value: "last")])
}

@Test func sharedLowererPreservesButtonClosureAction() {
    var calls = 0
    let element = requireElement(lower(Button("Run") { calls += 1 }))
    guard case .closure(let action)? = element?.action else {
        Issue.record("Expected closure action on lowered WebElementNode")
        return
    }
    action()
    #expect(calls == 1)
}

@Test func sharedLowererLowersAlignItemsOnAnyContainer() {
    let container = requireElement(lower(
        Div { Text("Centred") }
            .display(.flex)
            .alignItems(.center)
    ))
    #expect(container?.styles == [
        .init(name: "display", value: "flex"),
        .init(name: "align-items", value: "center"),
    ])

    let stretched = requireElement(lower(Div { Text("Stretched") }.alignItems(.stretch)))
    #expect(stretched?.styles == [.init(name: "align-items", value: "stretch")])
}

@Test func sharedLowererLowersInsetShorthandAndIndividualEdges() {
    let pinned = requireElement(lower(
        Div { Text("Scrim") }
            .position(.fixed)
            .inset(.zero)
    ))
    #expect(pinned?.styles == [
        .init(name: "position", value: "fixed"),
        .init(name: "inset", value: "0"),
    ])

    let vertical = requireElement(lower(Div { Text("Rail") }.inset(.vertical, .px(12))))
    #expect(vertical?.styles == [
        .init(name: "top", value: "12px"),
        .init(name: "bottom", value: "12px"),
    ])

    let leading = requireElement(lower(Div { Text("Edge") }.inset(.leading, .px(4))))
    #expect(leading?.styles == [.init(name: "left", value: "4px")])
}

@Test func sharedLowererLowersBothButtonLabelForms() {
    let plain = requireElement(lower(Button("Go") {}))
    #expect(plain?.tagName == "button")
    #expect(plain?.children.count == 1)
    guard case .text(let plainLabel)? = plain?.children.first else {
        Issue.record("Expected a raw text child for a string label")
        return
    }
    #expect(plainLabel == "Go")

    let composed = requireElement(lower(
        Button {
            HStack(spacing: .px(8)) {
                Image("avatar.png", alt: "")
                Text("Damian")
            }
        }
    ))
    #expect(composed?.tagName == "button")
    #expect(composed?.children.count == 1)
    guard case .element(let stack)? = composed?.children.first else {
        Issue.record("Expected the composed label to lower to an element")
        return
    }
    #expect(stack.tagName == "div")
    #expect(stack.children.count == 2)
}

@Test func sharedLowererLayersZStackChildrenInOneGridCell() {
    let layered = requireElement(lower(
        ZStack {
            Text("Card")
            Text("Badge")
        }
    ))
    #expect(layered?.tagName == "div")
    #expect(layered?.styles == [
        .init(name: "display", value: "grid"),
        .init(name: "align-items", value: "center"),
        .init(name: "justify-items", value: "center"),
    ])
    #expect(layered?.children.count == 2)

    guard case .element(let firstCell)? = layered?.children.first else {
        Issue.record("Expected each layered child to be wrapped in a cell")
        return
    }
    #expect(firstCell.styles == [.init(name: "grid-area", value: "1 / 1")])
    #expect(firstCell.children.count == 1)
}

@Test func sharedLowererMapsLayeredAlignmentOntoBothAxes() {
    let cases: [(Alignment, String, String)] = [
        (.center, "center", "center"),
        (.leading, "center", "start"),
        (.trailing, "center", "end"),
        (.top, "start", "center"),
        (.bottom, "end", "center"),
        (.topLeading, "start", "start"),
        (.topTrailing, "start", "end"),
        (.bottomLeading, "end", "start"),
        (.bottomTrailing, "end", "end"),
    ]

    for (alignment, block, inline) in cases {
        let node = requireElement(lower(ZStack(alignment: alignment) { Text("A") }))
        #expect(node?.styles == [
            .init(name: "display", value: "grid"),
            .init(name: "align-items", value: block),
            .init(name: "justify-items", value: inline),
        ])
    }
}

@Test func sharedLowererAlignsStacksOnTheirCrossAxis() {
    // A stack aligns on one axis, so a corner alignment contributes the half
    // that names the stack's cross axis.
    let cases: [(Alignment, String, String)] = [
        // alignment, VStack (inline cross axis), HStack (block cross axis)
        (.center, "center", "center"),
        (.leading, "flex-start", "flex-start"),
        (.trailing, "flex-end", "flex-end"),
        (.top, "flex-start", "flex-start"),
        (.bottom, "flex-end", "flex-end"),
        (.topLeading, "flex-start", "flex-start"),
        (.topTrailing, "flex-end", "flex-start"),
        (.bottomLeading, "flex-start", "flex-end"),
        (.bottomTrailing, "flex-end", "flex-end"),
    ]

    for (alignment, vertical, horizontal) in cases {
        let column = requireElement(lower(VStack(alignment: alignment) { Text("V") }))
        #expect(column?.styles.contains(.init(name: "align-items", value: vertical)) == true)

        let row = requireElement(lower(HStack(alignment: alignment) { Text("H") }))
        #expect(row?.styles.contains(.init(name: "align-items", value: horizontal)) == true)
    }
}

@Test func sharedLowererBuildsOverlayAndBackgroundAsLayeredStacks() {
    let overlaid = requireElement(lower(
        Text("Card").overlay(alignment: .top) { Text("Badge") }
    ))
    #expect(overlaid?.styles.contains(.init(name: "display", value: "grid")) == true)
    #expect(overlaid?.children.count == 2)

    // The receiver paints first, the overlay over it.
    #expect(firstTextContent(in: overlaid?.children.first) == "Card")
    #expect(firstTextContent(in: overlaid?.children.last) == "Badge")

    let backed = requireElement(lower(
        Text("Card").background { Div {} }
    ))
    #expect(backed?.children.count == 2)

    // The background paints first, the receiver over it.
    #expect(firstTextContent(in: backed?.children.last) == "Card")
}

private func firstTextContent(in node: WebNode?) -> String? {
    switch node {
    case .text(let content): return content
    case .element(let element): return element.children.lazy.compactMap(firstTextContent(in:)).first
    default: return nil
    }
}

@Test func sharedLowererCarriesDefaultFocusAsElementState() {
    let focused = requireElement(lower(Input().defaultFocus()))
    #expect(focused?.requestsFocus == true)

    let ordinary = requireElement(lower(Input()))
    #expect(ordinary?.requestsFocus == false)

    // It is element state, not a style or an attribute.
    #expect(focused?.styles.isEmpty == true)
    #expect(focused?.attributes.contains { $0.name == "autofocus" } == false)
}

@Test func sharedLowererCarriesKeyActionsInDeclarationOrder() {
    let node = requireElement(lower(
        Div { Text("Panel") }
            .attribute("tabindex", "-1")
            .onKeyDown("Escape") {}
            .onKeyDown("Enter") {}
    ))
    #expect(node?.keyActions.map(\.key) == ["Escape", "Enter"])
    #expect(requireElement(lower(Div { Text("Plain") }))?.keyActions.isEmpty == true)
}

@Test func sharedLowererCarriesDialogPresentationAsElementState() {
    var presented = true
    let binding = Binding(get: { presented }, set: { presented = $0 })

    let open = requireElement(lower(Dialog(isPresented: binding) { Text("Panel") }))
    #expect(open?.tagName == "dialog")
    #expect(open?.presentation == .modal)
    #expect(open?.dismissAction != nil)
    // A key handler only fires while focus is inside its element.
    #expect(open?.attributes.contains(.init(name: "tabindex", value: "-1")) == true)

    let nonModal = requireElement(lower(Dialog(isPresented: binding, isModal: false) { Text("Panel") }))
    #expect(nonModal?.presentation == .nonModal)

    presented = false
    let closed = requireElement(lower(Dialog(isPresented: binding) { Text("Panel") }))
    #expect(closed?.presentation == .dismissed)
}

@Test func dialogDismissActionWritesFalseBackThroughItsBinding() {
    var presented = true
    let binding = Binding(get: { presented }, set: { presented = $0 })
    let node = requireElement(lower(Dialog(isPresented: binding) { Text("Panel") }))

    guard case .closure(let dismiss)? = node?.dismissAction else {
        Issue.record("Expected a dismissal closure")
        return
    }
    dismiss()

    // Otherwise the DOM and the view tree disagree, and the next rebuild
    // re-opens a sheet the reader just closed.
    #expect(presented == false)
}

@Test func sheetEmitsTheDialogBesideItsReceiver() {
    var presented = true
    let binding = Binding(get: { presented }, set: { presented = $0 })

    let node = lower(Text("Page").sheet(isPresented: binding) { Text("Panel") })
    guard case .fragment(let children) = node else {
        Issue.record("Expected the receiver and its sheet side by side")
        return
    }
    #expect(children.count == 2)
    guard case .element(let dialog) = children[1] else {
        Issue.record("Expected the sheet to lower to a dialog element")
        return
    }
    #expect(dialog.tagName == "dialog")
    #expect(dialog.presentation == .modal)
}

@Test func sharedLowererCarriesTransitionPhasesAsElementState() {
    let node = requireElement(lower(
        Div { Text("Card") }
            .transition(enter: "sheet-in", exit: "sheet-out", durationMilliseconds: 280)
    ))
    #expect(node?.transitionPhases == .init(
        enter: "sheet-in",
        exit: "sheet-out",
        durationMilliseconds: 280
    ))
    // Phases are scheduling data, not a style declaration.
    #expect(node?.styles.isEmpty == true)

    #expect(requireElement(lower(Div { Text("Plain") }))?.transitionPhases == nil)
}

@Test func rawTransitionAndTransitionPhasesAreDifferentModifiers() {
    let raw = requireElement(lower(Div {}.transition("opacity 220ms ease")))
    #expect(raw?.styles == [.init(name: "transition", value: "opacity 220ms ease")])
    #expect(raw?.transitionPhases == nil)
}

@Test func sharedLowererLowersTheTruncationTrio() {
    // `text-overflow` only takes effect on a block whose overflow is clipped and
    // whose text does not wrap, so the three belong together.
    let truncated = requireElement(lower(
        Text("A name too long for its box")
            .whiteSpace(.nowrap)
            .overflow(.hidden)
            .textOverflow(.ellipsis)
    ))
    #expect(truncated?.styles == [
        .init(name: "white-space", value: "nowrap"),
        .init(name: "overflow", value: "hidden"),
        .init(name: "text-overflow", value: "ellipsis"),
    ])
}

@Test func sharedLowererPreservesCanonicalWhiteSpaceAndTextOverflowValues() {
    let whiteSpace: [(WhiteSpaceValue, String)] = [
        (.normal, "normal"),
        (.nowrap, "nowrap"),
        (.pre, "pre"),
        (.preWrap, "pre-wrap"),
        (.preLine, "pre-line"),
        (.breakSpaces, "break-spaces"),
    ]
    for (value, expected) in whiteSpace {
        let node = requireElement(lower(Text("Body").whiteSpace(value)))
        #expect(node?.styles == [.init(name: "white-space", value: expected)])
    }

    for (value, expected) in [(TextOverflowValue.clip, "clip"), (.ellipsis, "ellipsis")] {
        let node = requireElement(lower(Text("Body").textOverflow(value)))
        #expect(node?.styles == [.init(name: "text-overflow", value: expected)])
    }
}

private func lower<Content: View>(_ view: Content) -> WebNode {
    ViewNodeToWebNodeLowerer().lower(view.makeViewNode())
}

private func requireElement(_ node: WebNode) -> WebElementNode? {
    guard case .element(let element) = node else {
        Issue.record("Expected WebElementNode")
        return nil
    }
    return element
}
