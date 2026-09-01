# SwiftWebUI

SwiftWebUI is a SwiftUI-like web view DSL with an Embedded-compatible core. Views lower through concrete `ViewNode` and `WebNode` trees; static HTML/CSS output and browser DOM rendering consume the same semantic `WebNode` presentation.

## Example

```swift
import SwiftWebUIStatic

struct LandingPage: View {
    var body: some View {
        VStack(alignment: .leading, spacing: .px(16)) {
            Text("Build browser UI in Swift")
                .semanticRole(.h1)
                .font(.largeTitle)

            Text("One DSL, concrete renderer-neutral nodes.")
                .semanticRole(.p)
                .lineHeight(.multiple(1.7))
                .foregroundStyle(Color("var(--muted)"))

            Button("Continue") {}
                .buttonStyle(.primary)
        }
        .padding(.px(24))
        .background(Color("var(--panel)"))
        .navigationTitle("Landing")
    }
}

let rendered = HTMLRenderer().renderView(LandingPage())
let document = WebDocument(
    renderedView: rendered,
    stylesheetPath: "styles.css",
    scriptPath: "app.js"
)

let html = document.htmlString(prettyPrinted: false)
let css = rendered.cssString(prettyPrinted: false)
let js = rendered.jsString(prettyPrinted: false)
```

Use `import SwiftWebUI` when defining only shared views for Embedded or a runtime renderer. Use `import SwiftWebUIStatic` for static rendering; that module re-exports the core DSL.

`WebDocument` also describes documents that have to stand on their own before any
other code runs — a page that boots a WebAssembly bundle, for instance, where the
rendered view is a splash screen that must paint immediately and sit beside the
runtime's mount point:

```swift
import SwiftHTML // for the verbatim nodes below

WebDocument(
    renderedView: splash,
    stylesheetPath: "/styles.css",
    language: "nl",
    // A splash that waits on a second file to arrive has defeated its own purpose.
    stylesheetLinkPolicy: .always,
    renderedStyleDelivery: .inline,
    bodyScripts: [.module(bootScript)],
    bodySuffixNodes: [.element(.init(tag: "div", attributes: [.init("id", "app")], children: [], isVoid: false))]
)
```

## Architecture

```text
SwiftWebUI
Declarative View DSL
        |
        v
Concrete View Tree
        |
        v
Shared Semantic Web Tree
      /                     \
     v                       v
Static Renderer        Runtime Renderer
     |                       |
     v                       v
HTML / CSS / JS       Mounted Browser DOM
                             |
                             v
                Incremental Reconciliation
```

SwiftWebUI views are lowered into a concrete internal view tree. A single semantic lowering pass then produces a renderer-neutral web tree consumed by both the static and runtime renderers. The static renderer generates HTML, CSS, and JavaScript resources. The experimental runtime renderer mounts browser DOM and applies incremental updates after state changes, retaining the identity of unchanged DOM nodes during reconciliation.

`SwiftWebUIStatic` lowers the shared semantic tree into SwiftHTML and SwiftCSS ASTs before generating static HTML, CSS, and JavaScript resources.

`SwiftWebUIRuntime` remains experimental. `@State` works in subviews at any depth: the mounted root owns the storage and keys it on each view's structural identity, so a rebuilt view resolves to the same state. Give `ForEach` an `id:` (or `Identifiable` elements) when rows own state, otherwise rows are keyed by position. DOM reconciliation is still positional, so keyed list moves are not supported yet.

For detailed boundaries, compatibility constraints, reconciliation design, and runtime status, see [Architecture](ARCHITECTURE.md), [Embedded compatibility](Documentation/EmbeddedCompatibility.md), [Reconciliation](Documentation/Reconciliation.md), and [Runtime renderer](Documentation/RuntimePOC.md).
