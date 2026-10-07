# Runtime apps with SwiftWebUIRuntime

A runtime app is Swift compiled to WebAssembly. It mounts a view into a DOM
element and re-renders after state changes. `assets/runtime-app/` is a working
starter (a counter with a sheet).

The runtime is **experimental**: one mounted root per page, no router, no
hydration. It is in production use, but tell the user it is the younger half of
the library.

## Toolchain

Building needs a WebAssembly Swift SDK **and the compiler of exactly the same
version**. Check both before building:

```bash
swift sdk list
swift --version
```

- The starter's `Scripts/build.sh` defaults to `swift-6.3.3-RELEASE_wasm`
  (override with `SWIFT_SDK=…`). Use the non-`embedded` SDK.
- If `swift` is a different version from the SDK, the script runs the matching
  one through `swiftly` (`swiftly install 6.3.3`). If neither the SDK nor
  swiftly is installed, stop and tell the user what to install rather than
  attempting it: see swift.org's "Getting Started with Swift SDKs for WebAssembly".
- **`unknown argument: '-target-arch-variant'`** followed by a compiler crash
  while compiling package manifests means the Swift toolchain is older than the
  macOS SDK Xcode currently selects. Point host compilation at an older SDK:
  `HOST_SDK=/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk ./Scripts/build.sh`
  (list `/Library/Developer/CommandLineTools/SDKs/` to see what is installed).
- The first build fetches the WASI shim with `npm pack` into `Vendor/`; later
  builds need no network. Commit `Vendor/`.

A build takes about a minute. The page must be served over HTTP
(`./Scripts/serve.sh`); opening `dist/index.html` from disk does not work.

## Layout of the starter

```
Package.swift            executable target: SwiftWebUI, SwiftWebUIRuntime, JavaScriptKit, JavaScriptEventLoop
Resources/index.html     the document: <div id="app">, an import map, a module script calling init()
Resources/styles.css     custom properties, at-rules, selectors
Scripts/build.sh         swift package js → dist/, plus Resources/ and the vendored shim
Sources/App/App.swift    @main: SwiftWebUIRuntime.mount(RootView(), in: "app")
Sources/App/Views/       views
```

Keep the `swiftSettings` and `linkerSettings` in `Package.swift` as they are:
the reactor execution model is what keeps the module alive after `main()`
returns so that a click can call back into Swift.

`index.html` is hand-written in the starter. Whatever is inside `#app` shows
until the bundle has loaded and is then replaced — use it for a loading state.

## Keep Foundation out

Import `SwiftWebUI`, not `SwiftWebUIStatic`, in the app target. Anything that
links Foundation drags ICU into the bundle and takes it from about 1.5 MB
gzipped to many times that. `build.sh` prints the bundle size at the end; a
sudden jump means something imported Foundation. This applies to dependencies
too. For JSON, dates and networking, use JavaScriptKit to call the browser's own
(`fetch`, `JSON`, `Intl`) or a dependency known to build for Wasm without
Foundation.

## State

```swift
struct Counter: View {
    @State private var count = 0

    var body: some View {
        Button("Count: \(count)") { count += 1 }
    }
}
```

- `@State` works in a view at any depth; storage is kept by the mounted root and
  found again by the view's position in the tree. Flipping an `if`/`else` gives
  the new branch fresh state.
- `$count` is a `Binding`. Pass `Binding<T>` to children; build one by hand with
  `Binding(get:set:)`. There is no `@Binding` property wrapper — store
  `let value: Binding<Int>` and use `value.wrappedValue`.
- A state that is written from an action but only read on some branches should
  be read unconditionally somewhere in `body`, or it never binds to its slot.
- State declared inside a `Button` or `Link` label closure, or `Tab` content, is
  not kept. Declare it on the enclosing view.
- Each write rebuilds the root; several writes in one action rebuild several
  times. Batch into one assignment where it matters.

### Lists

```swift
ForEach(items, id: { $0.sku }) { item in Row(item: item) }
```

Give `ForEach` an `id:` (or `Identifiable` elements with `Int`/`String` ids)
whenever rows own state, otherwise rows are identified by position and state
shifts when an element is inserted or removed.

### Shared models

`@Observable` classes are tracked: a `body` that reads a property is rebuilt
when it changes. Share one with the environment, by type:

```swift
import Observation

@Observable
final class Basket: @unchecked Sendable {
    var lines: [Line] = []
}

struct Checkout: View {
    @Environment(Basket.self) private var basket
    var body: some View { Text("\(basket.lines.count) items") }
}

RootView().environment(basket)
```

`View.body` is not main-actor isolated, so a `@MainActor` model cannot be read
from it. The browser is single-threaded; mark models `@unchecked Sendable`
instead. Only objects travel through the environment — there is no
`.environment(\.key, value)` and no `EnvironmentValues`.

## Async work and loading data

There is no `.task` or `.onAppear`. Start work from `main()` after mounting, and
let an observed model carry the result into the view:

```swift
@Observable
final class Catalogue: @unchecked Sendable {
    var products: [Product]?          // nil while loading
    func load() async { products = await fetchProducts() }
}

@main
struct App {
    static func main() {
        #if arch(wasm32)
        JavaScriptEventLoop.installGlobalExecutor()   // without it, no await ever resumes
        #endif

        let catalogue = Catalogue()
        SwiftWebUIRuntime.mount(RootView().environment(catalogue), in: "app")
        Task { await catalogue.load() }
    }
}
```

A `Button` action is synchronous; start a `Task { … }` inside it for async work.
Calling `mount` again replaces the previous root and discards its state.

## Reading inputs

`Input` and `TextArea` have no value binding. Give the field an id and read the
DOM when the value is needed:

```swift
#if arch(wasm32)
import JavaScriptKit
#endif

enum Browser {
    static func value(ofFieldWithID id: String) -> String {
        #if arch(wasm32)
        JSObject.global.document.getElementById(id).value.string ?? ""
        #else
        ""
        #endif
    }
}

Input().id("name").attribute("type", "text")
Button("Greet") { greeting = "Hello, \(Browser.value(ofFieldWithID: "name"))" }
```

The field keeps what the visitor typed across re-renders, because unchanged DOM
nodes are kept. Wrap every JavaScriptKit use in `#if arch(wasm32)` so the
package still builds on the host for tests and editor support.

## Sheets, focus, keys, transitions

```swift
Button("Sign in") { isPresented = true }
    .sheet(isPresented: $isPresented) {
        VStack(alignment: .leading, spacing: .px(16)) {
            Input().attribute("type", "email").defaultFocus()
            Button("Continue") { isPresented = false }
        }
        .padding(.px(24))
    }
```

- `.sheet` is a real `<dialog>` shown modally: focus trap, Escape, inert
  background and scroll lock come from the browser. Style the `dialog` element
  itself in the stylesheet; recolour the backdrop with
  `--swiftwebui-dialog-backdrop`. `Dialog(isPresented:isModal:content:)` is the
  underlying view.
- `.defaultFocus()` focuses an element when it appears.
- `.onKeyDown("Escape") { … }` fires only while focus is inside the element; a
  non-interactive container needs `.attribute("tabindex", "-1")` and
  `.defaultFocus()` to receive keys.
- `.transition(enter: "sheet-in", exit: "sheet-out", durationMilliseconds: 280)`
  applies classes the stylesheet defines when an element arrives and before it
  is removed. Keep the number equal to the CSS duration.
- `Table(rows, id:sort:)` with a `@State var sort = TableSort("Name")` binding
  gives clickable sorting headers.

## Styling in a runtime app

Modifier declarations are applied as **inline styles**; no classes are
generated. So the stylesheet, as in a static site, carries custom properties,
at-rules and selectors — and a rule that must override a modifier needs
`!important`.

The starter links `styles.css` from `index.html`, so the page is styled while
the bundle loads. For CSS only known at run time (a theme chosen from data),
pass it at mount:

```swift
SwiftWebUIRuntime.mount(
    RootView(),
    in: "app",
    resources: RuntimeResources(stylesheets: [.external("theme.css"), .inline(css)])
)
```

## Routing

There is none. Read `location.pathname` through JavaScriptKit in `main()`, map
it to an enum, and `switch` on it in the root view; navigate with ordinary
`Link`s (a full page load) or by updating state and calling `history.pushState`
through JavaScriptKit. The host must answer unknown paths with `index.html` for
deep links to work — which is why the starter's `index.html` uses rooted paths.

## Known limits

- Inline SVG built with `Element("svg")` does not render in the runtime (elements
  are created without the SVG namespace). Use `Image("/icons/x.svg", alt: "")`,
  or a CSS `mask`/`background` from the stylesheet. It does work in static output.
- DOM reconciliation is positional: reordering a list re-renders rows rather
  than moving their nodes.
- `RemoteList`, and `.set(_:to:)`/`.setState` client-state actions, are
  static-only; use closures and state.
- `SwiftWebUIRuntimeConfiguration(reconciliationLogging: true)` passed to `mount`
  logs every DOM patch to the console, for debugging unexpected re-renders.

## Deploying

`dist/` is static files; host it anywhere that serves `.wasm` as
`application/wasm` (all common static hosts do). Serve it compressed — the
bundle shrinks to about a third.
