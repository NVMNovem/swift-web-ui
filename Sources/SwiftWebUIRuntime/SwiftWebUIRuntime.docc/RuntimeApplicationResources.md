# Runtime application resources

A runtime application can declare browser-facing stylesheet resources next to its
root view:

```swift
SwiftWebUIRuntime.mount(
    AboutView(),
    in: "app",
    resources: RuntimeResources(
        stylesheets: [
            .external("style.css"),
            .inline(":root { --accent: teal; }"),
        ]
    )
)
```

``RuntimeStylesheet/external(_:)`` creates a stylesheet link and preserves the URL
exactly. The browser resolves a relative URL such as `style.css` against the served
document URL. ``RuntimeStylesheet/inline(_:)`` inserts the supplied CSS unchanged in
a `style` element. Declaration order is preserved for both forms.

The runtime currently supports one mounted root, so installed stylesheets are owned
application-wide by that root. They are installed before the initial view tree,
retained for future cleanup, and remain independent from state invalidation and DOM
reconciliation. Element declarations lowered from view modifiers remain inline.

``RuntimeResources`` contains browser intent, not local filesystem paths. The
application build workflow owns CSS, images, fonts, and other static files and must
copy them into deployable output while preserving their browser-relative paths.
Typed SwiftCSS stylesheet-tree input is deferred; use external or inline CSS text.
