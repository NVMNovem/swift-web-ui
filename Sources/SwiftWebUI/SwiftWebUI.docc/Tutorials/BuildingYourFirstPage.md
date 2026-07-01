# Building Your First Page

Create a SwiftWebUI view and render it as a browser document.

## Overview

This tutorial builds a small static page with text, a button, extracted CSS, and a complete document wrapper.

## Create the View

```swift
import SwiftWebUI

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

The view tree renders to body content. ``WebDocument`` wraps that content in `html`, `head`, and `body` markup and links a stylesheet path only when CSS resources exist.
