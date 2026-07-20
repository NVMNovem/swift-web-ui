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

The experimental browser runtime can mount the deliberately small counter slice:

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

Run `./Scripts/dev-runtime-counter.sh` to build, serve, and automatically reload the
example while editing `Examples/RuntimeCounter/Sources/main.swift`. Generated browser
output is disposable and does not need to be opened or edited. The runtime mechanically
consumes the same lowered tags, attributes, and declarations as static rendering while
retaining closure actions and incrementally reconciling one mounted root. See [Runtime proof of concept](Documentation/RuntimePOC.md) for
the workflow and current packaging constraints.

## Architecture

```text
SwiftWebUI
View DSL + fixed-arity generic builders + state/binding/action intent
                              |
                              v
                      concrete ViewNode
                              |
                              v
                  shared semantic WebNode
                         /          \
                        v            v
          SwiftWebUIStatic       SwiftWebUIRuntime
     SwiftHTML + SwiftCSS AST    browser DOM POC
```

Normal composition does not use `AnyView`, view existentials, or dynamic view casts. `ViewBuilder` currently supports zero through ten children with concrete generic carriers. Optional branches, `if`/`else`, homogeneous arrays, and `ForEach` use dedicated typed carriers.

Parameter-pack builder carriers are deliberately deferred: Swift 6.3.3 Embedded fails while specializing that builder shape. The fixed-arity carriers are an internal compiler-compatibility choice and can later change without affecting `ViewNode` or renderer APIs.

`SwiftWebUIStatic` owns `HTMLRenderer`, `RenderedView`, style/resource registries, generated client-state and `RemoteList` JavaScript, `WebDocument`, and `PreviewExporter`. `SwiftWebUIRuntime` retains a runtime-only mounted tree and positionally reconciles observed `State` updates without replacing unchanged DOM nodes. See [Runtime reconciliation](Documentation/Reconciliation.md) for its current limits and keyed-identity design note.

See [ARCHITECTURE.md](ARCHITECTURE.md) and [Embedded compatibility](Documentation/EmbeddedCompatibility.md) for the detailed boundaries and validation commands.
