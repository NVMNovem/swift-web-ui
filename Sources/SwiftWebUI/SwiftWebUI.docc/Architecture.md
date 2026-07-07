# Architecture

Understand the ownership boundaries between SwiftWebUI, SwiftCSS, and SwiftHTML.

## Overview

SwiftWebUI is the browser UI layer in a layered Swift web ecosystem.

```text
SwiftWebUI
    View DSL, modifiers, semantic UI styling, state placeholders,
    rendered web resources, WebDocument

SwiftCSS
    CSS properties, values, declarations, stylesheet rendering

SwiftHTML
    HTML nodes, attributes, escaping, HTML rendering
```

The dependency direction is:

```text
User View
    -> SwiftWebUI
        -> SwiftCSS
        -> SwiftHTML
```

## Topics

### SwiftWebUI Ownership

- ``View``
- ``ViewBuilder``
- ``ModifiedView``
- ``ViewRendererProtocol``
- ``HTMLRenderer``
- ``RenderedView``
- ``WebDocument``

### Rendering Resources

- ``RenderContext``
- ``RenderedResources``
- ``StyleResource``
- ``ScriptResource``
- ``ResourceScope``

## Discussion

SwiftWebUI must not duplicate low-level HTML or CSS systems. If a feature is a new HTML element, attribute rendering rule, escaping rule, CSS property, CSS value, declaration, or stylesheet rendering behavior, it belongs in SwiftHTML or SwiftCSS first.

SwiftWebUI owns the higher-level web UI intent: primitive view types such as
``Text``, ``VStack``, ``Grid``, ``Button``, ``Link``, ``Image``, ``Article``,
``Section``, ``Form``, ``Label``, ``Input``, ``TextArea``, ``Footer``, and
``Template``;
view modifiers stored as data; semantic UI styling such as ``ButtonStyle`` and
``ButtonStyleToken``; state placeholders such as ``State`` and ``Binding``;
rendered resource collection; and ``WebDocument`` as a browser document target.

SwiftWebUI must not reimplement CSS properties, CSS values, CSS rendering,
HTML elements, HTML attributes, or HTML escaping. Those concerns belong to
SwiftCSS and SwiftHTML.

> Important: Do not reintroduce `SwiftWebUI.Border` or `SwiftWebUI.Shadow` as thin wrappers. Use SwiftCSS `Border` and `BoxShadow`, or add missing capabilities to SwiftCSS first.

Future packages such as SwiftMailUI should follow the same rule. A future SwiftMailUI package may depend on SwiftHTML and SwiftCSS, but it must not depend on SwiftWebUI.

SwiftWebUI may generate small JavaScript runtimes for declared behavior such as
client-state controls and ``RemoteList``. These runtimes should stay generic,
data-attribute driven, and tied to explicit SwiftWebUI declarations. Do not add
broad hand-written app-specific JavaScript to SwiftWebUI. A future SwiftJS
package should only be extracted after repeated runtime patterns emerge.

## Renderer Boundary

``ViewRendererProtocol`` is the public renderer boundary. It lets renderers own
their output type while preserving the existing user-facing ``View`` API.
``HTMLRenderer`` conforms with `Output == String` for direct HTML strings and
continues to expose `renderView(_:)` for separated ``RenderedView`` output and
`renderNodes(_:)` for SwiftHTML node output.

The current HTML renderer lowers views through an internal SwiftHTML bridge and
``RenderContext``. That bridge is an implementation detail of the browser HTML
renderer, not a second public view system. Future renderers, such as a DOM/WASM
renderer, should add their own renderer-owned output and lowering boundary
without requiring changes to application `View` declarations.
