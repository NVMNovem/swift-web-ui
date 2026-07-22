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

## Runtime example

The experimental browser DOM renderer with state-driven incremental reconciliation can mount the deliberately small counter slice:

```swift
import SwiftWebUI
import SwiftWebUIRuntime

struct CounterView: View {
    @State private var count = 0

    var body: some View {
        VStack(spacing: .px(8)) {
            Text("SwiftWebUI").font(.title)
            Text(String(count)).font(.caption)
            HStack {
                Button("Increment") { count += 1 }
                Button("Decrement") { count -= 1 }
            }
        }
        .padding(.px(8))
    }
}

@main
struct RuntimeCounterApp {
    static func main() {
        SwiftWebUIRuntime.mount(CounterView(), in: "app")
    }
}
```

Runtime applications can install an app-owned stylesheet without editing the HTML
shell:

```swift
SwiftWebUIRuntime.mount(
    CounterView(),
    in: "app",
    resources: RuntimeResources(
        stylesheets: [.external("style.css")]
    )
)
```

External URLs are browser-relative; inline CSS is also supported with `.inline(css)`.
View modifier declarations remain inline in runtime rendering, while the app
stylesheet supplies named classes, variables, pseudo-classes, and media queries.
The example build recursively copies `Examples/RuntimeCounter/Resources/` into
generated `dist/`, so relative images and other application assets keep their paths.

Run `./Scripts/dev-runtime-counter.sh` to build, serve, and automatically reload the
example while editing `Examples/RuntimeCounter/Sources/RuntimeCounter.swift`. Generated browser
output is disposable and does not need to be opened or edited. The runtime mechanically
consumes the same lowered tags, attributes, and declarations as static rendering while
retaining closure actions and incrementally reconciling one mounted root. See [Runtime proof of concept](Documentation/RuntimePOC.md) for
the workflow and current packaging constraints.

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
