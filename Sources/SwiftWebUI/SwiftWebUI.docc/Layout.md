# Layout

Express layout intent with stack and grid views.

## Overview

SwiftWebUI provides a small set of layout primitives:

```swift
VStack(alignment: .leading, spacing: .px(16)) {
    Text("Title")
    Text("Body")
}

HStack(alignment: .center, spacing: .px(8)) {
    Button("Cancel")
    Button("Save")
}

Grid(spacing: .px(12)) {
    Text("A")
    Text("B")
}
```

## Topics

### Containers

- ``VStack``
- ``HStack``
- ``Grid``
- ``Group``
- ``Div``
- ``Spacer``

### Layout Values

- ``Alignment``
- ``Edge``

## Discussion

`VStack`, `HStack`, and `Grid` are layout-intent views. Their current browser output uses generic containers plus SwiftCSS-backed declarations, but callers should treat the SwiftWebUI type as the public semantic contract.

Use ``Group`` for layout-neutral composition. An unmodified group renders transparently. If a group has modifiers or attributes, SwiftWebUI creates an implicit `div` so those modifiers have an element to attach to.

Use ``Div`` only when you specifically want a low-level `div` escape hatch.
