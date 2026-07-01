# Advanced Topics

Work with rendered resources, document export, and extension boundaries.

## Overview

``HTMLRenderer`` returns a ``RenderedView`` that separates HTML content from resources:

```swift
let rendered = HTMLRenderer().renderView(MyPage())

let html = rendered.htmlString()
let css = rendered.cssString()
let js = rendered.jsString()
```

This separation lets applications write HTML, CSS, and JavaScript as distinct files:

```swift
let document = WebDocument(
    title: "Preview",
    renderedView: rendered,
    stylesheetPath: "styles.css",
    scriptPath: "app.js"
)
```

## Topics

### Rendered Output

- ``RenderedView``
- ``RenderedContent``
- ``RenderedResources``
- ``StyleResource``
- ``ScriptResource``
- ``ResourceScope``

### Documents

- ``WebDocument``
- ``MetaTag``
- ``PreviewExporter``

### Architecture

- <doc:Architecture>
- <doc:ContributorGuide>

## Discussion

SwiftWebUI is not a site generator. It renders view trees and resources. Routing, file watching, asset pipelines, deployment, and server behavior should live in application code or separate packages.

When extending the framework, keep the architecture boundary clear: view intent belongs in SwiftWebUI, CSS primitives belong in SwiftCSS, and HTML primitives belong in SwiftHTML.
