# Getting Started

Define a renderer-neutral SwiftWebUI view.

## Overview

```swift
import SwiftWebUI

struct LandingPage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: .px(16)) {
            Text("Build browser UI in Swift")
                .semanticRole(.h1)
                .font(.largeTitle)

            Text("Concrete composition, one renderer-neutral tree.")
                .semanticRole(.p)

            Button("Continue") {}
                .buttonStyle(.primary)
        }
        .padding(.px(24))
    }
}

let node: ViewNode = LandingPage().makeViewNode()
```

The same declaration compiles in the Embedded core. For static output, import `SwiftWebUIStatic`; it re-exports the DSL and provides `HTMLRenderer`, rendered resources, `WebDocument`, and `PreviewExporter`.

```swift
import SwiftWebUIStatic

let rendered = HTMLRenderer().renderView(LandingPage())
let document = WebDocument(title: "Landing", renderedView: rendered)
let html = document.htmlString(prettyPrinted: true)
let css = rendered.cssString(prettyPrinted: true)
```

## Topics

- ``View``
- ``ViewBuilder``
- ``ViewNode``
- ``Text``
- ``VStack``
- ``Button``
- <doc:Architecture>
