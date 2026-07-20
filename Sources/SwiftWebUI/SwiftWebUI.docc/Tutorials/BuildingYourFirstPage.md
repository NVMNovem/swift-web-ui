# Building Your First Page

Create a SwiftWebUI view and render it as a browser document.

## Overview

This tutorial builds a small static page with text, a button, extracted CSS, and a complete document wrapper.

## Create the View

```swift
import SwiftWebUIStatic

struct FirstPage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: .px(12)) {
            Text("Hello")
                .semanticRole(.h1)
                .font(.largeTitle)

            Text("This page was declared in Swift.")
                .semanticRole(.p)

            Button("Continue")
                .buttonStyle(.primary)
        }
        .padding(.px(24))
    }
}
```

## Render the Page

```swift
let rendered = HTMLRenderer().renderView(FirstPage())
let document = WebDocument(title: "First Page", renderedView: rendered)

let html = document.htmlString(prettyPrinted: true)
let css = rendered.cssString(prettyPrinted: true)
```

## Discussion

The shared view first lowers to a concrete ``ViewNode``. The static module then produces body content and uses `WebDocument` to wrap it in `html`, `head`, and `body` markup, linking a stylesheet only when CSS resources exist.
