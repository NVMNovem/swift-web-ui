# Architecture

SwiftWebUI separates renderer-neutral view intent from static-site infrastructure.

## Module structure

```text
Application View
      |
      v
SwiftWebUI
  View, ViewBuilder, views, modifiers, State, Binding, ActionIntent
      |
      v
Concrete ViewNode
      |
      v
ViewNodeToWebNodeLowerer
      |
      v
Concrete WebNode
      +-----------------------+
      |                       |
      v                       v
SwiftWebUIStatic       SwiftWebUIRuntime
  SwiftHTML/CSS          mounted DOM patches
      |                       |
      v                       v
SwiftHTML/SwiftCSS       browser DOM
      |                       |
      v                       v
HTML/CSS/JS output      click -> State -> reconcile
```

`SwiftWebUI` is the existing public import and is the Embedded-compatible shared core. It depends on SwiftCSS for Embedded-compatible value and declaration types, but it does not depend on SwiftHTML or Foundation. It contains no HTML serialization, filesystem access, generated JavaScript, static resource registry, or DOM object.

`SwiftWebUIStatic` depends on the core, SwiftHTML, and SwiftCSS. It may use Foundation where document export needs URLs or filesystem access. It re-exports `SwiftWebUI` so static applications normally need one import.

`SwiftWebUIRuntime` is the browser runtime slice. It depends on the core and JavaScriptKit, installs application-declared external or inline stylesheets into the browser document head, initially mounts `WebNode` into a runtime-only `MountedNode` tree, diffs later `WebNode` values, and mechanically applies `DOMPatch` mutations while retaining browser node identity. It supports one mounted root and positional child reconciliation, and owns the `StateSlotStore` that keeps `@State` alive across rebuilds for subviews at any depth. It deliberately does not yet define keyed DOM identity, hydration, routing, or async work.

## Source organization

The logical shared core is physically organized under `Sources/SwiftWebUI/Backend`. `Attributes` contains property wrappers and result builders, `Protocols` contains public protocol boundaries, `Types` contains lightweight semantic/style values, and `Models` groups views, modifiers, styles, and renderer-neutral rendering models. Public views normally have one focused source file each.

`Models/Rendering` keeps the shared pipeline discoverable as one responsibility: semantic `ViewNode` models, concrete `WebNode` presentation models, and `ViewNodeToWebNodeLowerer`. Splitting those model declarations across focused files does not add lowering stages or backend semantics. The static and runtime modules remain separate top-level targets and continue to consume the same `WebNode` output mechanically.

The `Backend` directory is a source-organization convention, not a fourth architectural layer. There is intentionally no catch-all `Core` source folder.

## Concrete view traversal

`View` keeps the SwiftUI-like associated `Body` shape and has a concrete lowering operation:

```swift
public protocol View {
    associatedtype Body: View
    @ViewBuilder var body: Body { get }
    func makeViewNode() -> ViewNode
}
```

Primitive views implement `makeViewNode()` directly. Composed views use the default implementation that lowers their concrete `body`. Traversal never discovers primitive types with casts and never stores an HTML-rendering closure.

The recursive `ViewNode` enum represents DSL semantics: text roles, semantic/layout containers, controls, groups, and modifiers. `ViewNodeToWebNodeLowerer` is the only layer that interprets those semantics. It produces recursive `WebNode` values containing concrete tag names, canonical `WebAttribute` values, concrete `WebStyleDeclaration` property/value pairs, children, and action intent. It contains no serialized HTML/CSS, DOM object, generated resource, or static class hash.

## Builder composition

`ViewBuilder` preserves concrete types with `TupleView2` through `TupleView10`. Dedicated generic `OptionalView`, `ConditionalView`, `ArrayView`, and `ForEach` carriers cover optional, conditional, and homogeneous repeated content. The single-child expression remains its original concrete type.

The fixed arity is a Swift 6.3.3 Embedded compiler workaround. Parameter packs work in some isolated generic code, but the parameter-pack result-builder specialization used by the spike fails under the Embedded toolchain. Because builders lower immediately to `[ViewNode]`, a future parameter-pack carrier can replace the fixed carriers without changing renderer input.

`AnyView`, `[AnyView]`, `any View`, `[any View]`, and dynamic view casts are not part of normal traversal.

## Ownership rules

SwiftHTML owns HTML nodes, attributes, escaping, and HTML string rendering. SwiftCSS owns CSS properties, values, declarations, nodes, and CSS string rendering. SwiftWebUI must not duplicate either system.

The shared core owns:

- view declarations and renderer-neutral semantic/layout intent;
- concrete modifiers and compatible SwiftCSS values/declarations;
- reference-backed `State`, closure-backed `Binding`, stable state identity, and action intent;
- the renderer boundary and concrete `ViewNode`.
- concrete `WebNode` presentation and the single `ViewNodeToWebNodeLowerer` semantic pass.

The static module owns:

- mechanical `WebNode` to concrete SwiftHTML/SwiftCSS lowering;
- `HTMLRenderer`, `RenderedContent`, `RenderedResources`, and `RenderedView`;
- style hashing and resource registries;
- client-state and `RemoteList` generated JavaScript;
- `WebDocument`, `MetaTag`, `WebScript`, and `PreviewExporter`.

`WebDocument` describes a whole document, not only a rendered view wrapped in
markup. It can inline the rendered CSS as a `<style>` block instead of linking it,
force the stylesheet link independently of whether the view produced CSS, carry
verbatim head nodes for anything `MetaTag` cannot express, place body nodes before
and after the rendered view, and write inline `<script>` content — including
`type="module"` and `type="importmap"` — in the head or at the end of the body.

Together those cover the document that has to boot a WebAssembly bundle: a
build-time rendered splash and the runtime's mount point as siblings, styling that
needs no second round trip, and a loader that necessarily runs before any Swift
exists on the page. The loader stays the application's JavaScript; SwiftWebUIStatic
supplies the markup around it.

The runtime proof-of-concept module owns:

- browser-facing `RuntimeResources` and ordered stylesheet installation;
- installed stylesheet handles retained by the single application root, outside reconciliation;
- browser element lookup and mounting;
- runtime-only mounted nodes and positional paths;
- pure `WebNodeDiffer` patch production;
- mechanical `DOMPatchApplier` DOM mutation and mounted-metadata updates;
- JavaScriptKit DOM materialization and per-element click-handler retention/release;
- moving focus for elements that requested it, after they are in the document;
- per-element scoped key-down handler retention/release;
- the document body's scroll lock, as a counter held by the single mounted root;
- reconciled dialog presentation, and the close handler that writes dismissal back to the view tree;
- enter and exit transition scheduling, and the leaving DOM nodes that outlive their mounted counterparts;
- incremental reconciliation after renderer-neutral state invalidation.

Runtime element declarations stay inline. Named selectors, CSS custom properties,
pseudo-classes, media queries, transitions, and animations belong to app stylesheets.
Application build tooling—not the runtime or `WebNode`—owns filesystem discovery and
recursive copying of CSS and assets into deployable output. Typed SwiftCSS runtime
stylesheet input is deferred because the string/external resource boundary is the
straightforward public API under the selected Wasm SDK.

`RemoteList` remains static-only because its behavior is currently defined by generated fetch/template JavaScript. Binding-backed tabs and `.set` retain core state/action intent; the shared lowerer owns their presentation and the static backend alone serializes client-state metadata and registers JavaScript resources. Runtime client-state mutation actions remain intentionally unsupported, while closure actions drive the current Wasm runtime.

## Extension rules

- New core views and modifiers must lower to concrete `ViewNode`/`ViewModifierNode` data and receive their web meaning only in `ViewNodeToWebNodeLowerer`.
- No Foundation, filesystem, HTML strings, generated JavaScript, or static resource registries may enter the core.
- No dynamic cast may be used for view traversal or style/state discovery.
- Static and runtime renderers consume only `WebNode` and may not reinterpret container kinds, modifiers, font tokens, or other view semantics.
- Shared semantic changes require focused lowerer tests and backend tests where applicable.
- Runtime update behavior must pass through reconciliation and include differ and fake-backend applier tests.
- Runtime stylesheet resources must use `RuntimeResources`; reconciliation must not recreate document-head resources.
- Runtime assets remain application/build resources and must not enter `WebNode` or runtime filesystem logic.
- `WebNode` cannot carry DOM state, and content hashes or child position are not stable semantic identity.
- Keyed reconciliation requires explicit user or domain identity.
- Missing HTML primitives belong in SwiftHTML; missing CSS primitives belong in SwiftCSS.
- Do not reintroduce SwiftWebUI `Border` or `Shadow` wrappers.
- Public API and architecture changes require README, DocC, and architecture documentation updates.
- Core changes must pass the Swift 6.3.3 Embedded target build.
