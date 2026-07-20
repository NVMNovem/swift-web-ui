# AI Architecture Rules

- SwiftHTML owns HTML nodes, attributes, escaping, and rendering.
- SwiftCSS owns CSS properties, values, declarations, and rendering.
- SwiftWebUI owns the Embedded-compatible shared View DSL, concrete ViewNode, WebNode, ViewNodeToWebNodeLowerer, modifiers, semantic UI styling, state, binding, and action intent.
- SwiftWebUIStatic owns mechanical WebNode-to-SwiftHTML/SwiftCSS lowering, rendered resources, generated JavaScript, WebDocument, and preview/export helpers.
- SwiftWebUIRuntime owns mechanical WebNode-to-DOM lowering, event registration, invalidation, and the browser bridge.
- Runtime updates must go through the SwiftWebUIRuntime reconciliation pipeline.
- WebNode must never contain DOM handles, mounted state, dirty flags, or browser objects.
- New patch behavior requires focused WebNodeDiffer and DOMPatchApplier tests.
- Content hashes are not identity.
- Keyed lists require explicit user or domain identity; child position is not permanent semantic identity.
- New view and modifier semantics must be implemented in ViewNodeToWebNodeLowerer.
- Static and runtime renderers may not duplicate container, modifier, font-token, or control semantics.
- Shared semantic changes require shared-lowerer tests and static/runtime backend tests where applicable.
- Keep the SwiftWebUI core Embedded-compatible: do not add Foundation, filesystem access, HTML strings, generated JavaScript, or static resource registries.
- Do not use dynamic casts for view traversal, state serialization, or style discovery.
- Normal composition must not use AnyView, view existential storage, or type-erased rendering closures.
- Do not create custom HTML node systems in SwiftWebUI.
- Do not implement CSS rendering directly in SwiftWebUI.
- Do not reintroduce SwiftWebUI.Border or SwiftWebUI.Shadow thin wrappers.
- Do not create SwiftWeb as a separate package unless explicitly requested.
- Do not create SwiftMailUI or MailDocument yet.
- Future SwiftMailUI must not depend on SwiftWebUI.
- Never implement missing CSS properties, CSS values, or CSS rendering logic in SwiftWebUI. If a required CSS feature is missing from SwiftCSS, stop and clearly report what needs to be added to SwiftCSS first.

# README Example Maintenance

When public API changes add, remove, rename, or significantly improve user-facing SwiftWebUI features, review README.md.
If README.md contains an example, update that example so it reflects the current recommended API.
If README.md does not contain an example, add a small, focused example.
The README example should show the best current way to use SwiftWebUI, but it must stay concise.
Do not showcase every feature.
Prefer one realistic example that demonstrates the core flow: define a View, apply a few common modifiers, render it through WebDocument or PreviewExporter when relevant.
Do not include experimental or placeholder-only APIs unless they are essential to the current recommended usage.
Do not show unsupported dynamic behavior as if it works.
If a feature is static-only, keep the example honest.
After updating README.md, make sure the example compiles or is clearly marked as illustrative if it cannot be compiled directly.

# Documentation Requirements

Any change that:

- adds public API
- changes behavior
- adds a new modifier
- adds a new view
- changes architecture
- changes ownership boundaries

MUST update:

- DocC documentation
- README examples if relevant
- ARCHITECTURE.md if relevant

A pull request or Codex task is considered incomplete if documentation is not updated.

Documentation is part of the Definition of Done.

Core changes must also pass:

```sh
swift build --target SwiftWebUI --swift-sdk swift-6.3.3-RELEASE_wasm-embedded
```

## DocC Validation

Before running direct DocC conversion, generate SwiftWebUI symbol graphs:

```sh
swift package dump-symbol-graph
```

Then pass the generated symbol graph directory to DocC:

```sh
xcrun docc convert Sources/SwiftWebUI/SwiftWebUI.docc \
  --fallback-display-name SwiftWebUI \
  --fallback-bundle-identifier com.novem.swiftwebui \
  --fallback-bundle-version 0.0.1 \
  --additional-symbol-graph-dir .build/arm64-apple-macosx/symbolgraph \
  --output-path /tmp/SwiftWebUI.doccarchive
```

Without `--additional-symbol-graph-dir`, DocC cannot resolve SwiftWebUI core symbols such as `View`, `TabView`, or `Font`. Static-only APIs such as `WebDocument` belong to SwiftWebUIStatic.
