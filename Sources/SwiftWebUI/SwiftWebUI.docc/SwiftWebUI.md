# ``SwiftWebUI``

Build browser UI with a SwiftUI-like view DSL that renders to semantic HTML and extracted CSS resources.

## Overview

SwiftWebUI lets you describe static browser interfaces in Swift:

```swift
import SwiftWebUI

struct HelloPage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: .px(12)) {
            Text("Hello")
                .semanticRole(.h1)
                .font(.headline)

            Button("Continue")
                .buttonStyle(.primary)
        }
        .padding(.px(24))
    }
}

let rendered = HTMLRenderer().renderView(HelloPage())
let document = WebDocument(title: "Hello", renderedView: rendered)

let html = document.htmlString()
let css = rendered.cssString()
```

The package is intentionally layered. SwiftWebUI owns the web view DSL, modifiers, semantic UI styling, state placeholders, rendered resources, and ``WebDocument``. It delegates HTML nodes and escaping to SwiftHTML, and CSS properties, values, declarations, and rendering to SwiftCSS.

> Important: SwiftWebUI does not run Swift in the browser. Components such as ``TabBar`` and ``TabView`` can emit a small JavaScript resource for generated client-state changes, but arbitrary Swift closures are not translated to JavaScript.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Architecture>
- ``View``
- ``HTMLRenderer``
- ``WebDocument``
- ``RenderedView``

### Building Views

- <doc:Components>
- ``Text``
- ``Image``
- ``Link``
- ``Button``
- ``Group``
- ``Div``
- ``Article``
- ``Section``
- ``Footer``

### Layout Views

- <doc:Layout>
- ``VStack``
- ``HStack``
- ``Grid``
- ``Spacer``
- ``Alignment``

### Style APIs

- <doc:Styling>
- ``Font``
- ``Background``
- ``ButtonStyle``
- ``ButtonStyleToken``
- ``Edge``
- ``BorderLineStyle``
- ``TextTransform``
- ``TextAlignment``
- ``TextDecoration``

### State and Controls

- <doc:StateAndBindings>
- <doc:Navigation>
- <doc:Tabs>
- <doc:Forms>
- ``State``
- ``Binding``
- ``ClientStateValue``
- ``Tab``
- ``TabBar``
- ``TabView``
- ``Form``
- ``Label``
- ``Input``
- ``TextArea``

### Resources and Extensibility

- <doc:Images>
- <doc:AdvancedTopics>
- <doc:ContributorGuide>
- ``RenderedResources``
- ``RenderedContent``
- ``StyleResource``
- ``ScriptResource``
- ``ResourceScope``
- ``MetaTag``
- ``PreviewExporter``

### Tutorials

- <doc:BuildingYourFirstPage>
- <doc:BuildingNavigation>
- <doc:BuildingAContactForm>
- <doc:BuildingATabInterface>
