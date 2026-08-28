# Components

Compose semantic browser UI from SwiftWebUI primitive views.

## Overview

The core component model follows SwiftUI's shape: define reusable types that conform to ``View`` and return other views from `body`.

```swift
struct ProjectCard: View {
    var title: String
    var summary: String
    var destination: String

    var body: some View {
        Article {
            Link(destination: destination) {
                VStack(alignment: .leading, spacing: .px(8)) {
                    Text(title).semanticRole(.h2)
                    Text(summary).semanticRole(.p)
                }
            }
        }
        .class("project-card")
    }
}
```

## Topics

### Text and Media

- ``Text``
- ``Image``
- ``Link``

### Containers

- ``Group``
- ``Div``
- ``Article``
- ``Section``
- ``Footer``
- ``Element``

### Controls

- ``Button``
- ``Form``
- ``Label``
- ``Input``
- ``TextArea``
- ``Tab``
- ``TabBar``
- ``TabView``

## Discussion

``Button`` takes either a string or a content closure, the same pair ``Link``
offers. Reach for the content form whenever the control is more than a word —
it keeps the whole presentation inside the real control, so the focus ring
traces what the reader is actually clicking:

```swift
Button {
    HStack(spacing: .px(8)) {
        Image(avatarURL, alt: "")
            .frame(width: .px(24), height: .px(24))
            .clipShape(.capsule)
        Text(name)
    }
} 
```

> Note: Both initialisers build their label in a detached ``ViewContext``, as
> ``Link`` does. A `@State` value declared inside the closure does not bind to
> the mounted root's slot store and falls back to private storage — declare
> state on the enclosing view instead.

Prefer semantic views when they express the document structure. Use ``Article`` for self-contained content, ``Section`` for sectioning content, and ``Footer`` for footer content. Use ``Div`` as a low-level escape hatch.

``Element`` goes one level lower still, for markup SwiftWebUI attaches no semantics to — most often a foreign element such as `svg`:

```swift
Element("svg") {
    Element("circle")
        .class("ring")
        .attribute("cx", "40")
        .attribute("cy", "40")
        .attribute("r", "32")
}
.attribute("viewBox", "0 0 80 80")
```

It names a tag; it is not a way to write HTML strings into a view tree. The content is an ordinary view tree, attributes come from ``View/attribute(_:_:)``, and the name is written through to both backends verbatim so casing survives for the attributes that need it. Reach for it only when no semantic view fits.
