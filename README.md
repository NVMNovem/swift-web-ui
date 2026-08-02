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
    }
}

let rendered = HTMLRenderer().renderView(LandingPage())
let document = WebDocument(
    title: "Landing",
    renderedView: rendered,
    stylesheetPath: "styles.css",
    scriptPath: "app.js"
)

let html = document.htmlString(prettyPrinted: false)
let css = rendered.cssString(prettyPrinted: false)
let js = rendered.jsString(prettyPrinted: false)
```

Use `import SwiftWebUI` when defining only shared views for Embedded or a runtime renderer. Use `import SwiftWebUIStatic` for static rendering; that module re-exports the core DSL.

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

`SwiftWebUIRuntime` remains experimental and currently uses positional reconciliation; keyed list moves are not supported yet.

For detailed boundaries, compatibility constraints, reconciliation design, and runtime status, see [Architecture](ARCHITECTURE.md), [Embedded compatibility](Documentation/EmbeddedCompatibility.md), [Reconciliation](Documentation/Reconciliation.md), and [Runtime renderer](Documentation/RuntimePOC.md).
