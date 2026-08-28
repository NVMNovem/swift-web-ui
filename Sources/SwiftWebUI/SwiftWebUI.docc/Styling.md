# Styling

Apply visual styling through SwiftWebUI modifiers backed by SwiftCSS values and declarations.

## Overview

Styling modifiers attach concrete intent to a view node. `SwiftWebUIStatic` lowers that intent into SwiftCSS declarations, registers generated CSS classes, and keeps HTML output focused on structure.

```swift
Text("Hello")
    .font(.headline)
    .lineHeight(.multiple(1.7))
    .padding(.px(12))
    .background(Color("var(--panel)"))
    .foregroundStyle(Color("var(--text)"))
    .border(width: .px(1), color: Color("var(--border)"))
```

## Topics

### Typography

Use `LineHeightValue` to distinguish unitless multipliers from explicit lengths
and percentages. A unitless multiplier remains unitless in static CSS and the
runtime DOM:

```swift
Text("Readable body copy")
    .lineHeight(.multiple(1.7))
```

Use `.normal`, `.length(.px(28))`, or `.percent(170)` when those CSS semantics
are intended. Code that previously passed a `Length` should wrap it with
`.length(...)`; use `.multiple(...)` when the old value represented a unitless
line-height.

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
.aspectRatio(3, 2)
.objectPosition("center")
.alignItems(.center)
.alignSelf(.center)
.flexGrow(0)
.wordBreak(.breakWord)
.whiteSpace(.nowrap)
.textOverflow(.ellipsis)
.border(.bottom, "1px solid #eee")
.backdropFilter("blur(18px)")
.pointerEvents(.none)
.cursor(.pointer)
.position(.relative)
.top(.px(16))
.inset(.zero)
.zIndex(20)
.resize(.vertical)
.outline(.none)
.scrollMarginTop(.px(84))
```

SwiftWebUI stores these calls as modifier data and lowers them through SwiftCSS
properties and values such as `GridTemplateColumns`, `JustifyContentValue`,
`FlexWrapValue`, `Opacity`, `Transform`, `Transition`, `BackdropFilter`,
`OverflowValue`, `ObjectFitValue`, `AspectRatio`, `ObjectPosition`,
`AlignItemsValue`, `AlignSelfValue`, `FlexGrow`, `FlexShrink`, `FlexBasis`, `WordBreakValue`,
`WhiteSpaceValue`, `TextOverflowValue`,
`PointerEventsValue`, `CursorValue`, `PositionValue`, `Top`, `Inset`, `ZIndex`,
`ResizeValue`, `OutlineValue`, and `ScrollMarginTop`. Edge-specific borders
lower through the per-side properties `BorderTop`, `BorderRight`,
`BorderBottom`, and `BorderLeft`, with `.all` collapsing to the `Border`
shorthand. String-accepting modifiers such as `.gridTemplateColumns(...)`,
`.transform(...)`, `.transition(...)`, and `.backdropFilter(...)` accept CSS
strings because the corresponding SwiftCSS property value is intentionally broad.

### Truncating one line of text

`text-overflow` only takes effect on a block whose overflow is clipped and whose
text does not wrap, so the three modifiers belong together:

```swift
Text(name)
    .whiteSpace(.nowrap)
    .overflow(.hidden)
    .textOverflow(.ellipsis)
```

Prefer this to shortening the string in Swift. Only the browser knows the
rendered width of a name in the reader's font at the reader's size, so a
Swift-side truncation is a guess that CSS does not have to make.

### Enter and exit transitions

`.transition(_:)` writes a raw CSS `transition` string, which animates a property
change on an element that stays mounted. `.transition(enter:exit:durationMilliseconds:)`
is the other half — arriving and leaving:

```swift
Div {
    Text("Card")
}
.transition(enter: "sheet-in", exit: "sheet-out", durationMilliseconds: 280)
```

`enter` and `exit` name classes an application stylesheet defines; SwiftWebUI only
schedules them. The runtime adds `enter` on the frame *after* insertion, because
applying it in the same frame is the classic no-op — the browser never paints the
pre-transition state, so there is nothing to transition from. On removal it puts
`exit` on the element and holds it in the document for `durationMilliseconds`
before taking it out, which a synchronous removal would never allow.

The duration is a number rather than a CSS string because the runtime schedules
against it and cannot parse `280ms ease` to find out how long to wait. Keep it in
step with the duration in the stylesheet.

A reader who prefers reduced motion gets neither the animation nor the wait: the
element arrives and leaves immediately. Skipping the animation but keeping the
delay would be the worst of both.

> Note: A leaving element is out of the view tree straight away and lingers only
> in the DOM, so it still occupies layout until it goes. Take it out of flow in
> the `exit` class — `position: absolute` — when its siblings should close the
> gap immediately.

> Important: Enter and exit are browser-runtime only, and apply to an element
> that is removed, not one that is replaced. Static rendering has no moment of
> insertion, so it emits the element already wearing `enter`, and has no
> equivalent of an exit at all.

### Focus

`.defaultFocus()` is not styling — it asks the browser to move focus to the
element once it is in a live document. See <doc:Forms>.

### Buttons

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

Define button tokens with a stable class name and concrete SwiftCSS declarations. Protocol-erased custom button styles are not supported by the Embedded core.

Use raw CSS overloads only as escape hatches:

```swift
Text("Featured")
    .background("linear-gradient(90deg, #fff, #eef)")
```

## Discussion

SwiftWebUI should only model UI-level styling decisions. Missing CSS properties, values, or rendering behavior must be added to SwiftCSS before SwiftWebUI exposes a typed modifier for them.
