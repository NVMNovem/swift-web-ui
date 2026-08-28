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

ZStack(alignment: .top) {
    Image("cover.jpg", alt: "")
    Text("New")
}
```

## Topics

### Containers

- ``VStack``
- ``HStack``
- ``ZStack``
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

Any view can become a flex container in its own right. `.display(.flex)` paired
with `.alignItems(_:)` aligns every child on the cross axis, so a plain ``Div``
can centre its contents without borrowing a stack to do it:

```swift
Div {
    Text("Centred")
}
.display(.flex)
.alignItems(.center)
```

`.alignItems(_:)` sets `align-items` on the container. `.alignSelf(_:)` remains
the per-child override, and a stack's own `alignment` argument keeps setting the
same property for ``VStack`` and ``HStack``.

### Layering

``ZStack`` puts every child in the same box. It lowers to a `grid` whose children
all sit in cell `1 / 1`, not to absolute positioning: absolutely-positioned
children are out of flow, so the stack would collapse to zero height instead of
sizing to its largest child. Children paint in document order, so a layered stack
needs no hand-assigned `zIndex`.

`.overlay(alignment:content:)` and `.background(alignment:content:)` are sugar
over the same primitive — the receiver and the closure's content, in paint order:

```swift
Image("cover.jpg", alt: "")
    .overlay(alignment: .top) {
        Text("New")
    }
```

``Alignment`` names one axis at a time, so a layered stack centres the axis it
does not name: `.leading` and `.trailing` set the inline axis, `.top` and
`.bottom` the block axis, and `.center` sets both.

> Note: Sharing one grid cell needs a `grid-area` declaration per child, and the
> lowerer builds children generically. A layered stack therefore wraps each child
> in a `div` carrying that one declaration, and those wrappers are visible in the
> rendered output.

### Pinning to edges

`.inset(_:)` pins a positioned element to all four edges in one call:

```swift
Div {
    Text("Overlay")
}
.position(.fixed)
.inset(.zero)
```

An ``Edge`` set narrows it. `.all` lowers to the CSS `inset` shorthand; anything
narrower expands to `top`, `right`, `bottom`, and `left`, because CSS has no
`inset-top` property:

```swift
Div { Text("Rail") }
    .position(.absolute)
    .inset(.vertical, .px(12))
    .inset(.leading, .px(4))
```
