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
