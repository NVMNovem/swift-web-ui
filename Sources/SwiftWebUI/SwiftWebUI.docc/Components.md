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

Prefer semantic views when they express the document structure. Use ``Article`` for self-contained content, ``Section`` for sectioning content, and ``Footer`` for footer content. Use ``Div`` as a low-level escape hatch.
