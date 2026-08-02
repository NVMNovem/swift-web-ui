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

    #expect(node?.styles.suffix(2) == [
        .init(name: "padding", value: "4px"),
        .init(name: "padding", value: "8px"),
    ])
    #expect(node?.attributes == [
        .init(name: "data-kind", value: "sample"),
        .init(name: "class", value: "panel"),
        .init(name: "id", value: "main"),
    ])
    #expect(node?.children.count == 2)
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
