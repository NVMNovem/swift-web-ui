//
//  View+DragAndDropTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

import Testing
@_spi(Rendering) import SwiftWebUI
@_spi(Rendering) import SwiftWebUIStatic

@Suite struct ViewDragAndDropTests {
    @Test func onDragMakesANativeDragSourceThatReadsItsContentWhenTheDragStarts() {
        var title = "Draft"
        let node = requireElement(lower(Text("Card").onDrag { ItemProvider(object: title) }))

        #expect(node?.attributes.contains(.init(name: "draggable", value: "true")) == true)
        title = "Final"
        #expect(node?.dragSource?.representations() == [.init(contentType: .plainText, value: "Final")])
    }

    @Test func theDragSourceNearestTheViewWins() {
        let node = requireElement(lower(
            Text("Card")
                .onDrag { ItemProvider(object: "inner") }
                .onDrag { ItemProvider(object: "outer") }
        ))
        #expect(node?.dragSource?.representations().first?.value == "inner")
    }

    @Test func aViewWithoutDragAndDropCarriesNeither() {
        let node = requireElement(lower(Text("Plain")))
        #expect(node?.dragSource == nil)
        #expect(node?.dropTarget == nil)
        #expect(node?.attributes.contains { $0.name == "draggable" } == false)
    }

    @Test func onDropReportsTargetingAndHandsOverOnlyTheSupportedContent() {
        var isTargeted = false
        var received: [String] = []
        var location: Point?
        let binding = Binding(get: { isTargeted }, set: { isTargeted = $0 })
        let node = requireElement(lower(
            Div { Text("Inbox") }
                .onDrop(of: [.plainText], isTargeted: binding) { providers, point in
                    for provider in providers {
                        provider.loadObject(ofClass: String.self) { if let value = $0 { received.append(value) } }
                    }
                    location = point
                    return true
                }
        ))
        guard let target = node?.dropTarget else {
            Issue.record("Expected a drop target")
            return
        }
        let moving = DropInfo(location: Point(x: 3, y: 5), contentTypes: [.plainText, .html])

        #expect(target.supportedContentTypes == [.plainText])
        #expect(target.validateDrop(info: moving))
        target.dropEntered(info: moving)
        #expect(isTargeted)

        let dropped = DropInfo(
            location: Point(x: 10, y: 20),
            contentTypes: [.plainText, .html],
            representations: [
                .init(contentType: .html, value: "<i>card-7</i>"),
                .init(contentType: .plainText, value: "card-7"),
            ]
        )
        #expect(target.performDrop(info: dropped))
        #expect(!isTargeted)
        #expect(received == ["card-7"])
        #expect(location == Point(x: 10, y: 20))
    }

    @Test func leavingWithoutDroppingClearsTargeting() {
        var isTargeted = false
        let binding = Binding(get: { isTargeted }, set: { isTargeted = $0 })
        let target = requireElement(lower(
            Div {}.onDrop(of: [.url], isTargeted: binding) { _ in true }
        ))?.dropTarget
        let info = DropInfo(location: .zero, contentTypes: [.url])

        target?.dropEntered(info: info)
        #expect(isTargeted)
        target?.dropExited(info: info)
        #expect(!isTargeted)
    }

    @Test func theDropTargetNearestTheViewWins() {
        let node = requireElement(lower(
            Div {}
                .onDrop(of: [.json], isTargeted: nil) { _ in true }
                .onDrop(of: [.plainText], isTargeted: nil) { _ in true }
        ))
        #expect(node?.dropTarget?.supportedContentTypes == [.json])
    }

    @Test func staticRenderingKeepsTheDraggableAttributeButNoHandlers() {
        let html = HTMLRenderer().renderView(
            Div {
                Text("Card").onDrag { ItemProvider(object: "card") }
                Div {}.onDrop(of: [.plainText], isTargeted: nil) { _ in true }
            }
        ).htmlString()

        #expect(html.contains("draggable=\"true\""))
        #expect(!html.contains("dragstart"))
        #expect(!html.contains("ondrop"))
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
