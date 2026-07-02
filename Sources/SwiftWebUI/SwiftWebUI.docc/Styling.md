# Styling

Apply visual styling through SwiftWebUI modifiers backed by SwiftCSS values and declarations.

## Overview

Styling modifiers attach styling intent to a view. During rendering, SwiftWebUI converts that intent into SwiftCSS declarations, registers generated CSS classes, and keeps the HTML output focused on structure.

```swift
Text("Hello")
    .font(.headline)
    .padding(.px(12))
    .background(Color("var(--panel)"))
    .foregroundStyle(Color("var(--text)"))
    .border(width: .px(1), color: Color("var(--border)"))
```

## Topics

### Typography

- ``Font``
- ``TextTransform``
- ``TextAlignment``
- ``TextDecoration``

### Color and Background

- ``Background``

### Spacing and Box Styling

- ``Edge``
- ``BorderLineStyle``
- ``ClipShape``

### Low-Level Layout and Visual Modifiers

SwiftWebUI also exposes generic CSS-backed modifiers for layout primitives,
visual state, transforms, and positioning. These modifiers are available on any
``View`` and on chained ``ModifiedView`` values:

```swift
Div {
    Text("Featured project")
}
.display(.grid)
.gridTemplateColumns("repeat(3, minmax(0, 1fr))")
.justifyContent(.center)
.flexWrap(.wrap)
.opacity(0.48)
.transform("translateX(0)")
.transition("opacity 220ms ease, transform 280ms ease")
.overflow(.hidden)
.objectFit(.cover)
.backdropFilter("blur(18px)")
.pointerEvents(.none)
.cursor(.pointer)
.position(.relative)
.top(.px(16))
.zIndex(20)
.resize(.vertical)
.outline(.none)
.scrollMarginTop(.px(84))
```

SwiftWebUI stores these calls as modifier data and lowers them through SwiftCSS
properties and values such as `GridTemplateColumns`, `JustifyContentValue`,
`FlexWrapValue`, `Opacity`, `Transform`, `Transition`, `BackdropFilter`,
`OverflowValue`, `ObjectFitValue`, `PointerEventsValue`, `CursorValue`,
`PositionValue`, `Top`, `ZIndex`, `ResizeValue`, `OutlineValue`, and
`ScrollMarginTop`. String-accepting modifiers such as `.gridTemplateColumns(...)`,
`.transform(...)`, `.transition(...)`, and `.backdropFilter(...)` accept CSS
strings because the corresponding SwiftCSS property value is intentionally broad.

### Buttons

- ``ButtonStyle``
- ``ButtonStyleConfiguration``
- ``ButtonStyleToken``

## Examples

Use semantic roles for HTML meaning and font modifiers for visual presentation:

```swift
Text("Dashboard")
    .semanticRole(.h1)
    .font(.largeTitle)
```

Define app-specific tokens in your own module by extending SwiftCSS types:

```swift
extension Color {
    static let panel = Color("var(--panel)")
    static let muted = Color("var(--muted)")
}

Text("Muted copy")
    .foregroundStyle(.muted)
```

Use raw CSS overloads only as escape hatches:

```swift
Text("Featured")
    .background("linear-gradient(90deg, #fff, #eef)")
```

## Discussion

SwiftWebUI should only model UI-level styling decisions. Missing CSS properties, values, or rendering behavior must be added to SwiftCSS before SwiftWebUI exposes a typed modifier for them.
