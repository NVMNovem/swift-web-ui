# Embedded compatibility

## Status

The production `SwiftWebUI` target is the shared Embedded-compatible DSL/core. It builds with Swift 6.3.3 and `swift-6.3.3-RELEASE_wasm-embedded`. Static rendering is a separate `SwiftWebUIStatic` target and is not required to build under Embedded. The browser executable is packaged with the standard Wasm SDK because exhaustive SwiftCSS values may require full standard-library Unicode support; that backend choice does not weaken the independently validated core boundary.

```text
SwiftWebUI
  generic DSL + fixed-arity builders + state/binding/action intent
                                |
                                v
                        concrete ViewNode
                                |
                                v
                 shared concrete WebNode
                         /             \
                        v               v
SwiftWebUIStatic -> SwiftHTML/CSS   SwiftWebUIRuntime -> DOM
```

Both `WebNode` and `ViewNodeToWebNodeLowerer` are in the Embedded-compatible core. `SwiftWebUIRuntime` is a separate JavaScriptKit backend and is not part of the core Embedded build.

## Core boundary

The core contains `View`, `ViewBuilder`, primitive and container views, modifiers, `State`, `Binding`, action/state intent, a concrete recursive `ViewNode`, renderer-neutral `WebNode`, and the single `ViewNodeToWebNodeLowerer` semantic pass.

Primitive views lower directly. A composed view lowers its concrete `body`. Builder carriers and primitive nodes turn heterogeneous composition into concrete `[ViewNode]` children; the shared lowerer then resolves tags, layouts, attributes, styles, fonts, controls, and actions into `WebNode`. Backends receive no generic parameter pack, erased view, HTML closure, view existential, container kind, or modifier token.

The core does not import Foundation, SwiftHTML, or JavaScriptKit and does not own files, serialized HTML/CSS, generated JavaScript, static resources, class hashes, or DOM objects. It uses Embedded-compatible SwiftCSS values while lowering and stores only concrete property/value declarations in `WebNode`.

## Builder model

Production uses `TupleView2` through `TupleView10`. Zero and one expressions use `EmptyView` and the concrete expression type. `OptionalView<Content>`, `ConditionalView<TrueContent, FalseContent>`, `ArrayView<Content>`, and `ForEach<Data, Content>` cover dynamic builder shapes without existential storage.

The public SwiftUI-like syntax remains unchanged. Ten is the current maximum number of expressions in one builder block; additional children can be nested in `Group`, a stack, or another container.

## Why parameter packs are deferred

The isolated `EmbeddedCore` spike tested a parameter-pack `TupleView<each Content>` with Swift 6.3.3. Native compilation and its demo passed. The Embedded compiler did not.

Direct pack-element lowering reported:

```text
error: a protocol type cannot contain a generic method 'makeViewNode()'
in embedded Swift [#EmbeddedRestrictions]
```

Routing the call through a generic function reported:

```text
error: cannot specialize generic function or default protocol method in this
context [#EmbeddedRestrictions]
```

A final typed intermediate pre-lowered every expression so the pack expansion copied only concrete `ViewNode` fields. The compiler reached IR generation and terminated with signal 6:

```text
Metadata pointer requested in embedded Swift for type Text
fatal error encountered during compilation; please submit a bug report
metadata used in embedded mode
```

The stack identified the heterogeneous `ViewBuilder.buildBlock(_:)` specialization. This was a parameter-pack builder specialization/compiler limitation, not a renderer-protocol limitation. Fixed-arity carriers are therefore the current production compatibility design. They can later be replaced without changing `ViewNode` or renderer APIs.

## Conditional and repeated content

Optional, if/else, homogeneous array, and `ForEach` carriers compile in the production Embedded target. `ForEach` stores `[Content]`, so every iteration must produce the same concrete content type. These carriers do not fall back to `AnyView` or protocol existential storage.

The production Embedded demo covers:

- `State` and projected `Binding`;
- an `if`/`else` body;
- a button action closure;
- a modified stack;
- homogeneous `ForEach` content.

## Static-only boundary

`SwiftWebUIStatic` mechanically consumes `WebNode` to build SwiftHTML and SwiftCSS ASTs. It owns HTML/CSS string rendering, style hashing, resources, generated client-state and `RemoteList` JavaScript, `WebDocument`, `MetaTag`, and `PreviewExporter`. It re-exports the core module.

`RemoteList` is intentionally static-only because its current semantics are a generated fetch/template runtime. Binding-backed tabs and `.set` carry renderer-neutral state identity and value intent in core; the static module alone converts those values into data attributes and script resources.

## State and future runtime work

`State` uses reference-backed storage. `Binding` keeps closure-backed get/set operations and can carry a stable `StateIdentity`. Actions remain concrete closure or state-mutation intent. The core does not serialize arbitrary values with `String(describing:)` and does not dynamically cast state values.

The runtime mounts the shared presentation tree into runtime-only mounted nodes, retains closure actions, invalidates on state mutation, and positionally reconciles changed `WebNode` values. The core remains free of DOM handles and reconciliation state. The next runtime identity step is explicit keyed `ForEach` identity and state-slot ownership; content hashes and child position cannot provide that semantic identity.

## Validation

Use the matching compiler for every command:

```sh
SWIFT=/Users/vdkdamian/Library/Developer/Toolchains/swift-6.3.3-RELEASE.xctoolchain/usr/bin/swift

$SWIFT --version
$SWIFT package resolve
$SWIFT build
$SWIFT test
$SWIFT build --target SwiftWebUI \
  --swift-sdk swift-6.3.3-RELEASE_wasm-embedded
$SWIFT build --target SwiftWebUIEmbeddedDemo \
  --swift-sdk swift-6.3.3-RELEASE_wasm-embedded
```

Architecture scans for the core should show no erased traversal, dynamic casts, or unchecked concurrency escape hatches:

```sh
rg "AnyView|any View|\\[any View\\]|SwiftHTMLRenderable|as\\?|String\\(describing:" Sources/SwiftWebUI
```
