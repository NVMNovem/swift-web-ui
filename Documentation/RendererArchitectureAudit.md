# Renderer Architecture Audit

Date: 2026-07-07

## Scope

This audit reviewed the SwiftWebUI renderer boundary after SwiftHTML and
SwiftCSS moved to renderer-agnostic model/AST layers with renderer protocols,
string renderers, and tree dump renderers. The package currently resolves
against `swift-html` 0.2.0 and `swift-css` 0.2.0.

Reviewed files and types:

- `View`
- `ModifiedView`
- `RenderContext`
- `SwiftHTMLBridge`
- `HTMLRenderer`
- `StyleRegistry`
- `RenderedView`
- `RenderedResources`

## Baseline

`swift package resolve` completed successfully against:

- `swift-html` 0.2.0
- `swift-css` 0.2.0

`swift test` passed with 119 tests.

## Pure View / Model Types

These types are primarily SwiftWebUI view or output models:

- `View`: the declarative view contract. It should remain renderer-neutral at
  the API surface.
- `ModifiedView`: stores a `Content` view plus `[ViewModifierData]`. It is a
  model for modifier intent, not an output renderer.
- View primitives such as `Text`, `VStack`, `HStack`, `Grid`, `Button`, `Link`,
  `Image`, `Section`, `Article`, `Form`, `Label`, `Input`, `TextArea`,
  `Footer`, `Div`, `TabView`, `TabBar`, `Template`, and `RemoteList`: these
  express SwiftWebUI intent. Their concrete HTML lowering currently lives in
  extensions in `SwiftHTMLBridge.swift`, not in their stored model definitions.
- `ViewModifierData`: stores modifier intent. It does reference SwiftHTML
  attributes and SwiftCSS values/properties, so it is web-output-oriented rather
  than fully renderer-agnostic, but it does not itself render.
- `RenderedView`: a SwiftWebUI output model that separates rendered content
  from resources.
- `RenderedResources`, `StyleResource`, and `ScriptResource`: resource output
  models.

## Types That Currently Own Rendering

Rendering is currently owned by a small set of internal and public types:

- `HTMLRenderer`: public renderer entry point. It creates `RenderContext`, asks
  the view tree to lower to SwiftHTML nodes, and packages the result as
  `RenderedView` or a compact HTML string.
- `SwiftHTMLRenderable`: internal protocol used to identify views with direct
  SwiftHTML lowering.
- `SwiftHTMLBridge.swift`: contains almost all view-specific lowering to
  SwiftHTML nodes, SwiftHTML attributes, SwiftCSS properties, generated data
  attributes, and runtime registration.
- `RenderContext`: owns render-pass state, pending modifier application, CSS
  class registration, script runtime registration, and final resource
  extraction.
- `StyleRegistry`: owns generated CSS class identity and CSS text output for
  collected SwiftCSS declarations.
- `RenderedContent.htmlString`, `RenderedResources.cssString`, and
  `RenderedResources.jsString`: own string rendering of already-rendered output
  containers.
- `WebDocument`: owns full browser document rendering around `RenderedView`.
  This is document-target rendering, not view lowering.

## Is SwiftHTMLBridge Effectively The Renderer?

`SwiftHTMLBridge` is effectively the view-specific lowering layer of the current
HTML renderer, but it is not the whole renderer.

The whole current renderer is the combination of:

- `HTMLRenderer` as the public entry point.
- `View.renderSwiftHTML(context:)` as the recursive traversal hook.
- `SwiftHTMLRenderable` conformances in `SwiftHTMLBridge.swift` as the
  per-view lowering rules.
- `RenderContext` as render-pass state and resource collection.
- `StyleRegistry` as generated CSS class and stylesheet collection.
- `RenderedView` / `RenderedResources` as renderer output.

So the file named `SwiftHTMLBridge.swift` is doing the most renderer-specific
work, but `HTMLRenderer` remains the public renderer facade.

## Rename Or Split?

The safe immediate change is to add `ViewRendererProtocol` and make
`HTMLRenderer` conform.

`HTMLRenderer` should not be renamed right now because the current name is
accurate for the user-facing renderer that returns HTML strings, SwiftHTML
nodes, and `RenderedView` content/resources. Renaming it to
`SwiftWebUIRenderer` would be broader but less precise, and it would imply a
breaking public API change unless introduced as an additive alias or wrapper.

A full split into `ViewRendererProtocol` plus `HTMLViewRenderer` is useful once
there are at least two concrete renderers or once the HTML lowering is moved out
of the current `SwiftHTMLBridge` extension file. Until then, `HTMLRenderer`
should stay as the concrete HTML renderer and conform to the protocol.

Recommended current boundary:

```swift
public protocol ViewRendererProtocol {
    associatedtype Output
    func render<V: View>(_ view: V) -> Output
}
```

`HTMLRenderer` can satisfy this with `Output == String` while keeping
`renderView(_:)` and `renderNodes(_:)` unchanged.

## DOM/WASM Renderer Requirements

A future DOM/WASM renderer should not be forced through SwiftHTML string or node
output. To support it cleanly, SwiftWebUI needs these follow-up changes:

- Keep `View` and public view/modifier APIs free of renderer-specific method
  requirements.
- Treat `SwiftHTMLRenderable` and `SwiftHTMLBridge.swift` as HTML-renderer
  internals, not as the universal rendering contract.
- Consider introducing an intermediate SwiftWebUI render tree only when a
  second renderer proves the duplication cost. That tree would model UI intent
  after `body` expansion but before HTML/DOM-specific lowering.
- Separate resource registration from HTML assumptions. `RenderContext`
  currently stores pending modifiers, generated CSS classes, and script
  resources in one HTML-oriented pass. A DOM/WASM renderer may need state,
  event, and style registrations without generating classes or static scripts
  in the same shape.
- Move modifier application behind renderer-owned lowering APIs when DOM/WASM
  needs different behavior for attributes, style handles, event handles, and
  live node updates.
- Avoid adding new SwiftHTML-specific storage to core view models. New HTML
  nodes, attributes, escaping, or rendering support must still be added to
  SwiftHTML first.
- Avoid adding CSS rendering logic to SwiftWebUI. New CSS properties, values,
  declarations, and renderers still belong in SwiftCSS.

## What Should Stay Unchanged

- Public user-facing `View` APIs should stay unchanged.
- Existing modifiers should continue to store intent as `ViewModifierData`.
- `HTMLRenderer.render(_:)`, `renderView(_:)`, and `renderNodes(_:)` should
  remain source-compatible.
- Generated HTML, CSS, and JavaScript output should remain unchanged.
- `RenderedView` should continue to separate content from style and script
  resources.
- `WebDocument` should continue to wrap `RenderedView` for browser documents
  without becoming the core renderer.
- `SwiftHTML` should continue to own HTML nodes, attributes, escaping, and HTML
  rendering.
- `SwiftCSS` should continue to own CSS properties, values, declarations, and
  CSS rendering.

## Applied Refactor

The safe additive refactor was applied:

- Added public `ViewRendererProtocol`.
- Made `HTMLRenderer` conform with `Output == String`.
- Left public view APIs unchanged.
- Left generated HTML/CSS/JS output paths unchanged.
- Updated architecture documentation and DocC architecture topics.

No portfolio-specific code was added.
