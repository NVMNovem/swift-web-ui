# SwiftWebUI

[![CI](https://github.com/NVMNovem/swift-web-ui/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/NVMNovem/swift-web-ui/actions/workflows/ci.yml)
[![Swift 6.2+](https://img.shields.io/badge/Swift-6.2%2B-F05138?logo=swift&logoColor=white)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20Linux%20%7C%20WebAssembly-blue)](#)
[![Embedded Swift](https://img.shields.io/badge/Embedded%20Swift-compatible-8A2BE2)](https://www.swift.org/documentation/embedded/)

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
        .navigationIcon(.svg("<svg viewBox=\"0 0 16 16\"><circle cx=\"8\" cy=\"8\" r=\"8\"/></svg>"))
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

`navigationIcon(.svg(...))` accepts literal SVG markup and embeds it as a data
URL. Use `.url(...)` for an icon file; local files must be copied into the
deployed site by the application build tooling.

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

## Running in the browser

An application that runs in the browser is an `App` with a `Page`:

```swift
import SwiftWebUI
import SwiftWebUIRuntime

@main
struct ShopApp: App {
    var body: some Scene {
        Page {
            RootView()
        }
        .stylesheet(.external("styles.css"))
    }
}
```

`Page` is the web's `WindowGroup`. `App` supplies `main()`: it installs the JavaScript
event loop, creates the application and mounts the page into `#app`. A view starts
its own work with `.task`, which runs once the view is on the page and is cancelled
when it leaves:

```swift
struct RootView: View {
    @State private var shop: Shop?

    var body: some View {
        Text(shop?.name ?? "Loading…")
            .task { shop = await loadShop() }
    }
}
```

Two commands turn the package into a deployable `dist/`:

```sh
swift package --swift-sdk <wasm sdk> js -c release       # JavaScriptKit: compile
swift package --allow-writing-to-package-directory web   # SwiftWebUI: assemble
```

`swift package web` copies `Resources/`, generates an `index.html` with a loading
screen and loader unless the application brings its own, places the WASI shim, and
reports the bundle's size. See [Getting started in the browser](Documentation/GettingStarted.md)
and `Examples/Starter`.

## Embedded Swift

The same application builds with [Embedded Swift](https://www.swift.org/documentation/embedded/)
as well as with the full WebAssembly SDK, with no change to its code. Embedded Swift
links only the parts of the runtime and standard library the application reaches, so
the bundle a visitor downloads is much smaller: [ordessa-web](https://github.com/NVMNovem/ordessa-web),
a whole ordering site on SwiftWebUI, went from 11.07 MB (3.94 MB compressed) to
5.11 MB (about 1.6 MB) by switching.

`Examples/Starter` is set up for both. To build it with Embedded Swift:

```sh
cd Examples/Starter
export JAVASCRIPTKIT_EXPERIMENTAL_EMBEDDED_WASM=true    # JavaScriptKit's Embedded variant
swift package --swift-sdk swift-6.3.3-RELEASE_wasm-embedded js -c release
swift package --allow-writing-to-package-directory web
swift package --allow-network-connections local web-serve
```

The Embedded SDK comes in the same artifact bundle as the full one. Compared with the
full SDK, an Embedded application needs two things of its own:

- **Linker settings in its manifest.** `swift package js` passes the reactor flags only
  for the full SDK, and Embedded Swift also needs the `swiftUnicodeDataTables` library
  and an 8 MB stack. `Examples/Starter/Package.swift` adds all of them when
  `JAVASCRIPTKIT_EXPERIMENTAL_EMBEDDED_WASM` is `true`; copy that block.
- **`App.main()`.** It does what Embedded Swift leaves to the application: it runs the
  main actor on JavaScriptKit's event loop, exports the functions JavaScriptKit's
  JavaScript calls, and defines the concurrency runtime functions Embedded Swift 6.3
  leaves out. An application that is an `App` gets all of that for free.

CI builds the Starter in release with Embedded Swift and presses its button in Chromium,
so both of these are checked on every change.

### What changes in the API

Embedded Swift has no runtime metadata, reflection or key paths, and no existentials of
a protocol with generic requirements, which `View` is. SwiftWebUI is written so that
code reads the same in both builds, and where SwiftUI's API depends on one of those, it
offers a spelling that works everywhere:

- **Environment values are keyed by type, not by key path.** Declare an
  `EnvironmentKey`, place a value with `.environment(AccentKey.self, .red)` and read it
  with `@Environment(AccentKey.self)`. Objects are read by their type, as in SwiftUI:
  `@Environment(Basket.self)`.
- **No key paths anywhere.** `ForEach` takes `id:` as a closure (`id: { $0.code }`)
  rather than `\.code`.
- **No `AnyView`.** A builder block holds up to ten expressions (nest more in a `Group`
  or a stack), and every iteration of a `ForEach` produces the same view type.
- **`@Observable` comes from `SwiftObservation`**, from
  [swift-observation](https://github.com/NVMNovem/swift-observation). Apple's
  `Observation` is not available to Embedded Swift 6.3; `SwiftObservation` re-exports it
  wherever it exists and supplies its own otherwise, so a model is written once.
- **Keep views visible to the compiler.** A `private` or `fileprivate` view, view
  helper returning `some View`, or `View` extension is read as an existential and
  refused. In a release build the same holds for any non-public `some View` in a
  generic context (an internal `extension View` helper, a generic view); make it public
  or build with `-Xswiftc -enable-testing`.
- **Your own code follows Embedded Swift's rules**: no Foundation, typed `throws`
  instead of `any Error`, no `weak`, no `@MainActor` (use a global actor of your own).

See [Embedded compatibility](Documentation/EmbeddedCompatibility.md) for how the core
and the runtime are built to fit, and the compiler limits behind each rule.

## Localization

A string literal in `Text`, `Button` or `Link` is a localization key, as in SwiftUI; a
`String` value is shown verbatim. Catalogs come from
[SwiftLocalization](https://github.com/NVMNovem/swift-localization), which `SwiftWebUI`
re-exports.

```swift
struct CartSummary: View {
    let count: Int
    let customer: String

    var body: some View {
        VStack(alignment: .leading) {
            Text("cart.title")           // catalog key
            Text("\(count) items")       // "%lld items", pluralized per locale
            Text(customer)               // a value: never localized
            Button("Order") {}
        }
    }
}

let rendered = HTMLRenderer().renderView(
    CartSummary(count: 3, customer: "Ada")
        .localizationCatalog(.localizable)   // generated from Localizable.xcstrings
        .locale("nl-BE")
)
```

Add `SwiftLocalizationPlugin` to the target that holds `Localizable.xcstrings` to get
`LocalizationCatalog.localizable`. Without a catalog, or for a key it does not have,
the literal renders as written. The locale is always explicit: neither the process nor
the browser locale is read. A view reads the locale in effect with
`@Environment(LocaleIdentifier.self)`. See the Localization article in the DocC documentation for
the current limitations.

## Tables

`Table` shows rows as columns, lowering to real `table` markup with a plain
default look. Sorting is state the application owns: pass a `TableSort` binding
and every column with something to sort by becomes a header button.

```swift
struct ProductsTable: View {
    @State private var sort = TableSort("Name")
    let products: [Product]

    var body: some View {
        Table(products, id: { $0.id }, sort: $sort) {
            TableColumn("Name", value: { $0.name })

            // Sorted on the amount behind the cell, not the text in it.
            TableColumn("Price", width: .px(96), alignment: .trailing, value: { $0.cents }) { product in
                Text(product.formattedPrice)
            }
        }
        .stickyHeader()
        .minWidth(.px(720))
    }
}
```

Column width and alignment belong to the column; everything else is an ordinary
modifier on the table, which is also the element the defaults are declared on, so
a modifier overrides them.

## Drag and drop

`onDrag` and `onDrop` take SwiftUI's arguments and lower to the browser's own
HTML drag and drop. Content travels as text keyed by MIME type, so `ItemProvider`
holds strings and `UTType` names MIME types (`.plainText` is `text/plain`).
Browser-runtime only.

```swift
Text(card.title)
    .onDrag { ItemProvider(object: card.id) }

VStack { ForEach(done, id: { $0 }) { Text($0) } }
    .onDrop(of: [.plainText], isTargeted: $isTargeted) { providers in
        providers.first?.loadObject(ofClass: String.self) { id in
            if let id { done.append(id) }
        }
        return true
    }
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

`SwiftWebUIRuntime` remains experimental. `@State` works in subviews at any depth: the mounted root owns the storage and keys it on each view's structural identity, so a rebuilt view resolves to the same state. Give `ForEach` an `id:` (or `Identifiable` elements) when rows own state, otherwise rows are keyed by position. Keyed rows are reconciled by identity, so inserting, removing or reordering them moves their existing DOM nodes instead of rewriting them; an unkeyed list is still positional.

For detailed boundaries, compatibility constraints, reconciliation design, and runtime status, see [Architecture](ARCHITECTURE.md), [Embedded compatibility](Documentation/EmbeddedCompatibility.md), [Reconciliation](Documentation/Reconciliation.md), [Runtime renderer](Documentation/RuntimePOC.md), and [Getting started in the browser](Documentation/GettingStarted.md).
