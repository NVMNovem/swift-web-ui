# Getting Started

Render a SwiftWebUI view into HTML, CSS, and optional JavaScript resources.

## Overview

A SwiftWebUI screen is a type that conforms to ``View`` and returns other views from its `body`.

```swift
import SwiftWebUI

struct LandingPage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: .px(16)) {
            Text("Build browser UI in Swift")
                .semanticRole(.h1)
                .font(.largeTitle)

            Text("SwiftWebUI renders semantic HTML and extracted CSS.")
                .semanticRole(.p)
                .foregroundStyle(Color("var(--muted)"))

            Button("Continue")
                .buttonStyle(.primary)
        }
        .padding(.px(24))
        .background(Color("var(--panel)"))
    }
}
```

Use ``HTMLRenderer`` when you want the rendered content and resources separately:

```swift
let rendered = HTMLRenderer().renderView(LandingPage())

let bodyHTML = rendered.htmlString(prettyPrinted: false)
let css = rendered.cssString(prettyPrinted: true)
let js = rendered.jsString(prettyPrinted: true)
```

Use ``WebDocument`` when you want a complete browser document:

```swift
let document = WebDocument(
    title: "Landing",
    renderedView: rendered,
    stylesheetPath: "styles.css",
    scriptPath: "app.js"
)

let html = document.htmlString(prettyPrinted: true)
```

## Topics

### Create a View

- ``View``
- ``ViewBuilder``
- ``Text``
- ``VStack``
- ``Button``

### Render Output

- ``HTMLRenderer``
- ``RenderedView``
- ``RenderedContent``
- ``RenderedResources``
- ``WebDocument``

## Discussion

SwiftWebUI output is static by default. The renderer walks the view tree, creates SwiftHTML nodes, collects SwiftCSS declarations into generated class rules, and returns a ``RenderedView``. When a view uses generated client-state behavior, such as ``TabView`` with a ``Binding``, the renderer also collects a JavaScript resource.

> Tip: Importing SwiftWebUI also makes SwiftCSS value types available, including `Length` and `Color`, because SwiftWebUI re-exports SwiftCSS.
