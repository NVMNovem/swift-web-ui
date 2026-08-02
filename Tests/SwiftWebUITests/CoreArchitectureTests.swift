//
//  CoreArchitectureTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

import Testing
@testable import SwiftWebUI
import SwiftWebUIStatic

@Test func fixedArityBuilderSupportsTenChildren() {
    let view = VStack {
        Text("0")
        Text("1")
        Text("2")
        Text("3")
        Text("4")
        Text("5")
        Text("6")
        Text("7")
        Text("8")
        Text("9")
    }

    requireTenChildren(view.content)
    #expect(textValues(in: view.makeViewNode()) == ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"])
}

@Test func optionalConditionalAndForEachLowerWithoutErasure() {
    struct ContentView: View {
        let showSubtitle: Bool
        let values: [String]

        var body: some View {
            VStack {
                if showSubtitle {
                    Text("Subtitle")
                }

                if values.isEmpty {
                    Text("Empty")
                } else {
                    Text("Values")
                }

                ForEach(values) { value in
                    Text(value)
                }
            }
        }
    }

    #expect(
        textValues(in: ContentView(showSubtitle: true, values: ["A", "B"]).makeViewNode())
            == ["Subtitle", "Values", "A", "B"]
    )
    #expect(
        textValues(in: ContentView(showSubtitle: false, values: []).makeViewNode())
            == ["Empty"]
    )
}

@Test func representativeStaticParityUsesConcreteASTs() {
    let rendered = HTMLRenderer().renderView(
        VStack {
            Text("Header")
            Button("Continue") {}
            Text("Footer")
        }
        .padding(.px(8))
    )

    #expect(rendered.content.html.count == 1)
    #expect(rendered.htmlString().contains("<span>Header</span>"))
    #expect(rendered.htmlString().contains("<button data-swiftwebui-action=\"closure-placeholder\">Continue</button>"))
    #expect(rendered.htmlString().contains("<span>Footer</span>"))
    #expect(rendered.cssString().contains("padding: 8px"))
}

@Test func buttonActionClosureRemainsInCoreIntent() {
    var actionWasCalled = false
    let node = Button("Continue") {
        actionWasCalled = true
    }.makeViewNode()

    guard case .button(let button) = node,
          case .closure(let action)? = button.action else {
        Issue.record("Expected a concrete button node with its action closure")
        return
    }

    action()
    #expect(actionWasCalled)
}

private func requireTenChildren<
    C0: View,
    C1: View,
    C2: View,
    C3: View,
    C4: View,
    C5: View,
    C6: View,
    C7: View,
    C8: View,
    C9: View
>(_ content: TupleView10<C0, C1, C2, C3, C4, C5, C6, C7, C8, C9>) {}

private func textValues(in node: ViewNode) -> [String] {
    switch node {
    case .empty, .input, .textArea, .spacer:
        []
    case .text(let text):
        [text.content]
    case .container(let container):
        container.children.flatMap(textValues)
    case .button(let button):
        textValues(in: button.label)
    case .link(let link):
        textValues(in: link.label)
    case .image:
        []
    case .tabControl(let control):
        control.tabs.flatMap { textValues(in: $0.label) + textValues(in: $0.content) }
    case .group(let children):
        children.flatMap(textValues)
    case .modified(let modified):
        textValues(in: modified.content)
    }
}
