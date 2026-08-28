# Architecture

Understand the renderer-neutral core and static-renderer boundary.

## Overview

```text
SwiftWebUI DSL
    -> concrete ViewNode
        -> ViewNodeToWebNodeLowerer
            -> concrete WebNode
        -> SwiftWebUIStatic -> SwiftHTML.HTMLNode + SwiftCSS AST
        -> SwiftWebUIRuntime -> browser DOM proof of concept
```

``View`` keeps an associated ``View/Body`` and lowers through ``View/makeViewNode(in:)``. Primitive views produce ``ViewNode`` directly; composed views lower their concrete body. The internal Rendering SPI then lowers view semantics exactly once into `WebNode`. Renderers consume only concrete tags, attributes, styles, children, and action intent and do not rediscover view types.

``ViewBuilder`` uses concrete `TupleView2` through `TupleView10`, plus ``OptionalView``, ``ConditionalView``, ``ArrayView``, and ``ForEach``. These carriers preserve heterogeneous static types without `AnyView`, existential storage, parameter packs, or dynamic casts.

Lowering threads a ``ViewContext`` carrying the view's structural position. Each carrier appends the component that describes how it descends -- a tuple slot, a conditional branch, an optional's unwrapped case, or a keyed collection element -- which yields the ``ViewIdentityPath`` used to key ``State`` storage. The context is traversal-only: it never reaches `WebNode` or the renderers.

## Core ownership

SwiftWebUI owns views, semantic/layout intent, concrete modifiers, state/binding/action intent, `ViewNode`, `WebNode`, and `ViewNodeToWebNodeLowerer`. It depends on Embedded-compatible SwiftCSS values during semantic lowering. `WebNode` carries concrete tag names and property/value declarations, but no serialized HTML/CSS, generated resources, class hashes, files, or browser objects.

SwiftHTML owns HTML nodes, attributes, escaping, and string rendering. SwiftCSS owns CSS properties, values, declarations, nodes, and string rendering. Missing low-level capabilities must be implemented in their owning package rather than duplicated here.

## Source organization

The shared module is organized under `Sources/SwiftWebUI/Backend` without changing the logical core boundary. Property wrappers and result builders live under `Attributes`; protocol boundaries under `Protocols`; lightweight semantic and style values under `Types`; and views, modifiers, styles, and renderer-neutral rendering models under `Models`.

The rendering model folder groups `ViewNode`, `WebNode`, their focused supporting models, and the single `ViewNodeToWebNodeLowerer` semantic pass. Individual public views and modifier concerns use focused files for discoverability. This physical organization does not introduce another backend: SwiftWebUIStatic and SwiftWebUIRuntime remain the only consumers after shared lowering.

## Renderer ownership

The separate `SwiftWebUIStatic` module mechanically converts `WebNode` to SwiftHTML/SwiftCSS ASTs and owns `HTMLRenderer`, rendered output/resource models, style hashing, generated JavaScript, `WebDocument`, and `PreviewExporter`. Static applications import that module; it re-exports SwiftWebUI.

The separate `SwiftWebUIRuntime` module owns browser mounting, a runtime-only mounted tree, positional `WebNode` diffing, mechanical DOM patch application, and JavaScriptKit event handlers. It applies lowered tags, attributes, styles, children, and closure actions for one mounted root without replacing unchanged DOM nodes. JavaScriptKit and mounted state do not enter the core.

Focus is modelled as element state, not as an imperative call a view can make:
``ViewModifierNode/defaultFocus`` becomes `WebElementNode.requestsFocus`, and the
mounter and the differ reconcile it like any other element data. The mounter
focuses a handle only after inserting it, because `focus()` on a detached node is
a silent no-op, and the differ emits a focus patch only on the transition into
requesting focus, so a rerender never reclaims focus an element already has.

Key handling follows the click path rather than the focus one, because a handler
is a registration rather than a piece of reconciled state:
``ViewModifierNode/onKeyDown(key:action:)`` becomes `WebElementNode.keyActions`,
the mounter installs one scoped handler per element, and every registration is
released alongside the click registration when a subtree goes away.

Stopping the page behind a presented view from scrolling is a document-level side
effect rather than element state, so it lives entirely in SwiftWebUIRuntime as a
reference count held by the mounted root. It has no ``ViewModifierNode`` case and
no public modifier, because a counter any caller could increment is one that ends
up unbalanced.

Dialog presentation follows the focus pattern rather than the click one:
``ContainerKind/dialog(presentation:onDismiss:)`` becomes
`WebElementNode.presentation`, and the runtime presents an element only once it
is in the document. Dismissal is the one place state travels the other way — the
browser closes a dialog on Escape or its `cancel` event without consulting the
view tree, so the runtime registers a close handler that writes back through the
binding and takes the same `ViewInvalidation` hop a click action takes.

`RemoteList` remains static-only because it is currently defined by generated fetch/template JavaScript. Static client-state mutation actions remain a static resource feature. The runtime uses child position only as a traversal location; it does not yet define keyed identity, state slots, moves, or hydration. Removed subtrees recursively release retained handlers, while closure-bearing elements conservatively replace their handler registration after rerender because closures have no stable token.

## Embedded builder choice

Swift 6.3.3 Embedded crashes or diagnoses unsupported specialization for the parameter-pack result-builder design tested by the project spike. Fixed-arity carriers are an internal compatibility choice; replacing them later does not require a change to ``ViewNode`` or renderer APIs.

## Topics

- ``View``
- ``ViewBuilder``
- ``ViewNode``
- ``ModifiedView``
- ``ViewModifierNode``
- ``ViewRendererProtocol``
