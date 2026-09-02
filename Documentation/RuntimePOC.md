# SwiftWebUIRuntime architecture

`SwiftWebUIRuntime` is the browser DOM backend for SwiftWebUI. It is deliberately small and is not production-ready.

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
- `State`, including in subviews at any depth, backed by mounted state slots
- keyed `ForEach` identity through `id:` or `Identifiable`
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

`navigationTitle` and `navigationIcon` are lowered as document metadata rather
than `WebNode` content. The mounted root reconciles the title and owns one
managed `<link rel="icon">` for the active view; changing or clearing the
modifier updates or removes that link without recreating the mounted body tree.
Local favicon files remain application build assets.

```swift
SwiftWebUIRuntime.mount(
    RootView(),
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

## Implemented runtime guarantees

- an Embedded-compatible SwiftWebUI `View` can lower to `ViewNode` in a Wasm browser build;
- shared `ViewNode` semantics lower once to `WebNode` and then materialize as browser DOM nodes;
- a DOM click can invoke a retained Swift action closure;
- Swift `State` mutations invalidate the mounted root;
- state mutation can invalidate the mounted root;
- rebuilding and diffing `WebNode` updates changed content through focused patches;
- unchanged mounted nodes retain their browser identity;
- removed or replaced subtrees recursively release their action registrations;
- an external stylesheet is installed once and survives repeated invalidation;
- named rules, CSS variables, hover and media rules affect runtime DOM;
- recursively packaged relative assets load from the served root.

## Intentionally unsupported

- child moves in the DOM differ
- middle insertion with preserved sibling identity
- coalescing several state writes into one rebuild
- fine-grained state dependency tracking
- multiple mounted roots
- `RemoteList`
- routing
- hydration
- static client-state mutation actions
- CSSOM or stylesheet generation from typed SwiftCSS trees
- async API calls

`ForEach` element IDs now key state slots, so row state follows its element. The next reconciliation step is flowing those IDs into a stable `WebIdentity`, followed by a keyed mounted-child map and insert/remove/move patches that preserve DOM identity across reordering. Position, tag names, text, and rendered/content hashes are not valid substitutes for that user or domain identity. See [Runtime DOM reconciliation](Reconciliation.md).
