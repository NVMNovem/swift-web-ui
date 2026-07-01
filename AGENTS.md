# AI Architecture Rules

- SwiftHTML owns HTML nodes, attributes, escaping, and rendering.
- SwiftCSS owns CSS properties, values, declarations, and rendering.
- SwiftWebUI owns the web View DSL, modifiers, semantic UI styling, state placeholders, rendered web resources, and WebDocument.
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

Without `--additional-symbol-graph-dir`, DocC cannot resolve SwiftWebUI symbols such as `View`, `TabView`, `Font`, or `WebDocument`.
