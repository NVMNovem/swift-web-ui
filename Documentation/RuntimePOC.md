# SwiftWebUIRuntime proof of concept

`SwiftWebUIRuntime` is the first browser-testable runtime slice for SwiftWebUI. It is deliberately small and is not production-ready.

## Architecture

```text
SwiftWebUI View
      |
      v
concrete ViewNode
      |
      v
ViewNodeToWebNodeLowerer
      |
      v
concrete WebNode
      |
      v
WebNodeDiffer(old, new)
      |
      v
DOMPatch[] -> DOMPatchApplier
      |
      v
MountedNode + browser DOM

click -> retained Swift closure -> State mutation
      -> renderer-neutral invalidation -> rebuild ViewNode
      -> lower new WebNode -> reconcile the mounted DOM
```

The DOM backend consumes only `WebNode`; it never dynamically casts Swift view types or interprets `ContainerKind`, `ViewModifierNode`, or `Font`. SwiftWebUI core remains free of DOM objects and JavaScriptKit.

The native-testable mounted layer retains elements, text nodes, canonical attributes/styles, positional children, and per-element action registrations. The pure differ produces deterministic patches, and the JavaScriptKit backend mechanically creates or updates DOM nodes with `document.createElement`, `document.createTextNode`, text-node values, attributes, DOM style properties, child operations, and retained `JSClosure` click handlers.

## JavaScriptKit choice

The POC uses JavaScriptKit `JSObject` and `JSClosure` directly. JavaScriptKit 0.56.1 supports Swift 6.3 and includes Embedded Swift event-loop fixes. BridgeJS is promising for generated, typed DOM bindings, but its API is still documented as experimental and would add macro/binding-generation work unrelated to proving the runtime loop. A later runtime can revisit BridgeJS once the DOM surface and package workflow stabilize.

## Rendering support

- all tags, attributes, styles, fragments, and child order represented by shared `WebNode`;
- stack/grid/semantic-container and modifier meanings supplied by the shared lowerer;
- `State`
- Button closure actions
- one mounted root
- positional reconciliation for text, attributes, styles, actions, children, and ordinary node replacement

The runtime applies concrete element declarations inline. It does not know whether a
declaration came from a stack, font token, padding modifier, or another DSL feature.
Separately, `RuntimeResources` installs ordered external stylesheet links or inline
`style` elements before the initial view mount. This app stylesheet supplies named
selectors, CSS variables, pseudo-classes, media queries, transitions, and animations;
it is retained by the single mounted root and is not part of reconciliation. The
runtime does not generate CSS classes or reuse the static `StyleRegistry`.

```swift
SwiftWebUIRuntime.mount(
    CounterView(),
    in: "app",
    resources: RuntimeResources(
        stylesheets: [.external("style.css")]
    )
)
```

The browser resolves `style.css` relative to the served document. `.inline(css)` is
available for authored CSS text. Typed SwiftCSS stylesheet trees are deferred: the
current public SwiftCSS APIs do not improve this focused ownership boundary enough to
justify another traversal/rendering path in the runtime.

## Development workflow

From the package root, run one command:

```sh
./Scripts/dev-runtime-counter.sh
```

The command builds the Wasm executable, creates and validates a fresh browser bundle,
starts a local server, prints its URL, and watches the application and runtime Swift
sources. On macOS it opens the browser automatically. Every successful rebuild causes
the page to reload without a manual refresh. Stop the workflow with Control-C.

The application developer edits only:

```text
Examples/RuntimeCounter/Sources/RuntimeCounter.swift
```

`Resources/index.html`, the vendored WASI shim, PackageToJS, import maps, generated
JavaScript, Wasm, and the server are workflow infrastructure. A contributor does not
create or edit them while developing the counter. Set `SWIFTWEBUI_OPEN_BROWSER=0` to
disable automatic browser opening, or set `SWIFTWEBUI_RUNTIME_PORT` to use a port
other than 8080.

The development server injects a small polling client into the served HTML in memory;
it does not modify the maintained resource or generated output. The client polls a
local revision endpoint every 500 milliseconds. The build helper assembles a complete
staging bundle and swaps it into place only after validation, so the server announces
a new revision only for a successful build. Failed builds leave the last working page
running; saving after a fix triggers another build.

The developer-facing layout is:

```text
Examples/RuntimeCounter/
├── Sources/
│   ├── RuntimeCounter.swift
│   └── AboutView.swift
├── Resources/
│   ├── index.html
│   ├── style.css
│   └── assets/
│       └── runtime-fixture.svg
├── Vendor/
│   └── browser_wasi_shim/
└── dist/                       generated and ignored

Scripts/
├── build-runtime-counter.sh
├── serve-runtime-counter.sh
└── dev-runtime-counter.sh
```

Only the build helper creates `dist`. Everything needed to regenerate it lives
outside that directory. Manual changes inside `dist` are discarded.

## Build details and validation

`build-runtime-counter.sh` invokes PackageToJS with Swift 6.3.3 and the standard
`swift-6.3.3-RELEASE_wasm` SDK. SwiftWebUI itself is still validated separately
with the Embedded SDK; the browser executable uses the full Wasm standard library
because exhaustive SwiftCSS value support includes Unicode-aware String operations. SwiftPM uses
`/private/tmp/swiftwebui-runtime-counter` as its default scratch path, outside the
repository, while PackageToJS writes into a fresh temporary package directory for
each invocation. The script copies the complete `Resources` directory and required
files from `Vendor`, validates `.dist-staging`, and then replaces the complete `dist`
directory recursively, preserving every relative file path. It rejects resource and
output symlinks rather than following browser-facing paths outside the resource root.
It never asks PackageToJS to write into an existing `dist` and never
merges a build with stale output. Repeated builds are therefore idempotent and
produce the same content-hashed resource manifest. Validation compares every regular
file under `Resources` byte-for-byte with the same relative path under `dist` and
reports a precise missing path. Atomic replacement preserves the last validated
bundle when rebuilding or staging validation fails.

`dist` is fully generated. Manual changes inside it are discarded by the next build;
maintained HTML, Swift, vendored dependencies, and scripts all live outside it. The
example uses its own external SwiftPM scratch directory so unrelated package builds
cannot invalidate its plugin cache and dependency inspection does not traverse a
scratch directory under the macOS Documents/File Provider repository.

As an advanced option, override the scratch location for a build with:

```sh
SWIFTWEBUI_RUNTIME_SCRATCH_PATH=/another/path \
  ./Scripts/build-runtime-counter.sh
```

Run the standalone packaging validator against the current output with:

```sh
./Scripts/validate-runtime-counter.sh
```

To build twice and compare the two relative file manifests, run:

```sh
./Scripts/check-runtime-counter-reproducibility.sh
```

The executable uses the WASI reactor ABI because PackageToJS initializes a reactor
through its generated JavaScript. A command-style `_start` executable is incompatible
with JavaScriptKit's browser lifecycle, so the `SwiftWebUIRuntimeCounter` target keeps
`-Xclang-linker -mexec-model=reactor` in `Package.swift`. Its linker settings also
export Swift's `__main_argc_argv` entry point so PackageToJS can invoke the Swift
`@main` type after WASI initialization. The build does not set the legacy
`JAVASCRIPTKIT_EXPERIMENTAL_EMBEDDED_WASM` compatibility variable; that mode is
neither needed nor appropriate for the standard Wasm backend build.

PackageToJS generates `index.js`, whose public browser entry point is `init(options)`.
The HTML therefore imports and awaits `init()`; it does not import `main` or call the
lower-level `instantiate()` function.

PackageToJS also generates a bare import of `@bjorn3/browser_wasi_shim` in
`platforms/browser.js`. Browsers cannot resolve npm package names by themselves. The
source HTML import map resolves that name to the locally vendored version 0.3.0 at
`vendor/browser_wasi_shim/index.js`. The complete transitive ESM graph is copied into
`dist`, so the final served example has no CDN or internet dependency.

Maintained workflow files:

- `Examples/RuntimeCounter/Sources/RuntimeCounter.swift`
- `Examples/RuntimeCounter/Resources/index.html`
- `Examples/RuntimeCounter/Vendor/browser_wasi_shim/`
- `Scripts/build-runtime-counter.sh`
- `Scripts/serve-runtime-counter.sh`
- `Scripts/dev-runtime-counter.sh`
- `Scripts/validate-runtime-counter.sh`
- `Scripts/check-runtime-counter-reproducibility.sh`

Generated files include:

- `Examples/RuntimeCounter/dist/index.js`
- `Examples/RuntimeCounter/dist/instantiate.js`
- `Examples/RuntimeCounter/dist/runtime.js`
- `Examples/RuntimeCounter/dist/platforms/`
- `Examples/RuntimeCounter/dist/SwiftWebUIRuntimeCounter.wasm`
- the copied HTML and vendored shim under `Examples/RuntimeCounter/dist/`
- copied `style.css` and `assets/runtime-fixture.svg`

## Why this is not `swift run` yet

PackageToJS is distributed by JavaScriptKit as a SwiftPM command plugin with the
declared custom verb `js`. Its supported entry point is therefore `swift package js`.
SwiftPM cannot expose that dependency plugin under an application-defined spelling
such as `swift package runtime-demo` without adding another command plugin that owns
the orchestration.

`swift run SwiftWebUIRuntimeCounter` is also not equivalent. `swift run` selects,
builds, and launches a host executable. It does not build the product for the
Wasm SDK, run PackageToJS, assemble browser resources, or start an HTTP
server. In addition, `SwiftWebUIRuntime.mount` deliberately fails outside a Wasm
browser build. Renaming the executable to `RuntimeCounter` would make the command
look nicer but would not change those semantics.

The development script is the single public workflow today and delegates packaging
to `build-runtime-counter.sh`, which owns the PackageToJS-specific invocation. A
future `SwiftWebUIRuntime` command plugin could
offer a generic package command once it can own application discovery, resource and
vendor provisioning, browser packaging, serving, watching, and Xcode integration
without pushing those details into each application target.

`serve-runtime-counter.sh` remains available as an infrastructure helper for an
already-built bundle, but contributors normally use `dev-runtime-counter.sh`.

The second span initially displays `0`; after three clicks it displays `3`.

If Playwright and Chromium are available, the checked-in smoke test verifies the
initial value, three clicks, the final value, root/button/count-span DOM identity,
text-only mutations, and browser console errors:

```sh
node Examples/RuntimeCounter/smoke-test.mjs
```

The counter action remains entirely in
`Examples/RuntimeCounter/Sources/RuntimeCounter.swift`; no application-specific JavaScript
implements increment behavior.

## What this proves

- an Embedded-compatible SwiftWebUI `View` can lower to `ViewNode` in a Wasm browser build;
- shared `ViewNode` semantics lower once to `WebNode` and then materialize as browser DOM nodes;
- a DOM click can invoke a retained Swift action closure;
- Swift `State` performs the counter mutation;
- state mutation can invalidate the mounted root;
- rebuilding and diffing `WebNode` updates only the changed count text;
- the root, both buttons, and count span remain the same browser objects;
- removed or replaced subtrees recursively release their action registrations;
- no handwritten app-specific JavaScript performs counter logic.
- an external stylesheet is installed once and survives repeated invalidation;
- named rules, CSS variables, hover and media rules affect runtime DOM;
- recursively packaged relative assets load from the served root.

## Intentionally unsupported

- keyed semantic identity or child moves
- middle insertion with preserved sibling identity
- state slots
- multiple mounted roots
- `ForEach`
- `RemoteList`
- routing
- hydration
- static client-state mutation actions
- CSSOM or stylesheet generation from typed SwiftCSS trees
- async API calls

The next reconciliation step is explicit `ForEach` element IDs flowing into a stable `WebIdentity`, followed by a keyed mounted-child map and insert/remove/move patches that preserve state across reordering. Position, tag names, text, and rendered/content hashes are not valid substitutes for that user or domain identity. See [Runtime DOM reconciliation](Reconciliation.md).
