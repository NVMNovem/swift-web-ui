# Styling Architecture Audit

## Boundary

SwiftCSS owns raw CSS:

- `CSSProperty` types such as `Border`, `Padding`, `Gap`, `Display`, `BackgroundColor`, `BorderRadius`, `Width`, and `Height`.
- `CSSValue` types such as `Color`, `Length`, `Angle`, `Percentage`, `Time`, and property-specific value objects.
- CSS rendering and low-level escape hatches such as `RawProperty`.

SwiftWebUI owns the view DSL:

- View and modifier data.
- UI-facing style semantics and modifier APIs.
- Lowering UI abstractions into SwiftCSS properties during rendering.
- Re-exporting SwiftCSS so downstream users can access CSS values through `import SwiftWebUI`.

SwiftWebUI may depend on SwiftCSS. SwiftCSS must not depend on SwiftWebUI.

## Duplicate Names

| Name | SwiftCSS responsibility | SwiftWebUI responsibility | Decision |
| --- | --- | --- | --- |
| `Border` | CSS `border` property. | Previously a string wrapper that immediately created `SwiftCSS.Border`. | Removed from SwiftWebUI. Border modifiers store `SwiftCSS.Border` directly. The typed `.border(width:style:color:)` overload composes a `SwiftCSS.Border` from SwiftCSS values without introducing a SwiftWebUI border model. |
| `Color` | CSS color value and `color` property. | Previously a UI color wrapper. | Removed from SwiftWebUI. Modifiers accept `SwiftCSS.Color` directly. Rendering qualifies property construction as `SwiftCSS.Color` where needed. |
| `Length` | CSS length value. | Previously an integer/float literal friendly UI DSL length. | Removed from SwiftWebUI. Modifiers accept `SwiftCSS.Length` directly. |

## Duplicate Concepts

| Concept | SwiftCSS owner | SwiftWebUI owner | Decision |
| --- | --- | --- | --- |
| Background | `BackgroundColor` and raw `background` properties. | `Background`, a UI modifier value that can carry a SwiftCSS `Color` or raw background value. | Keep in SwiftWebUI as a modifier value. Rendering lowers typed colors to `BackgroundColor` and raw background values to `RawProperty("background", ...)`. Prefer `.background(Color("var(--panel)"))`, or an app-owned extension such as `.background(.panel)`; keep `.background("...")` as a low-level escape hatch. |
| Shadow | `BoxShadow` CSS property. | No separate owner after this audit. | Removed the raw `Shadow` wrapper. The `.shadow(...)` modifier stores `BoxShadow` directly and keeps a string convenience overload as an escape hatch. Add a future `ShadowStyle` only if it models semantic elevations, states, or typed shadow components. |
| Font | `FontSize`, `FontWeight`, `FontFamily`, and related CSS properties. | `Font`, a SwiftUI-like semantic visual styling API lowered into SwiftCSS declarations. | Keep `Font` in SwiftWebUI. It provides UI-level font roles and system font intent rather than duplicating CSS property rendering. |
| Padding | `Padding` CSS property and edge-specific raw properties. | `.padding(...)` modifier accepting SwiftCSS `Length` and SwiftWebUI `Edge.Set`. | Keep modifier in SwiftWebUI; CSS property and value remain SwiftCSS. Edge expansion happens at render lowering. |
| Gap | `Gap` CSS property. | `.gap(...)` modifier and stack spacing values. | Keep modifier in SwiftWebUI; rendered property remains SwiftCSS `Gap`. |
| Alignment | Flex alignment values such as `AlignItemsValue`. | `Alignment` enum for stack APIs. | Keep in SwiftWebUI. It is a view-layout abstraction lowered to SwiftCSS flex alignment values. |
| Radius | `BorderRadius` CSS property. | `.cornerRadius(...)` modifier using `Length`. | Do not add a SwiftWebUI `Radius` wrapper unless semantic radius tokens are needed. |
| Frame | `Width`, `Height`, and `MaxWidth` CSS properties. | `.frame(width:height:maxWidth:)` modifier. | Keep frame as SwiftWebUI layout DSL; render to SwiftCSS size properties. |

## Current Rule

Do not add SwiftWebUI types that only store a CSS string and immediately return a same-meaning SwiftCSS property or value. Use SwiftCSS values and properties directly in modifier storage, with SwiftWebUI convenience overloads only where they express view or semantic intent.

Add a SwiftWebUI style type only when it provides UI semantics, such as named tokens, state-aware styling, multiple CSS declarations, typed components, or design-system concepts.

App/site design tokens should live outside SwiftWebUI:

```swift
extension Color {
    static let panel = Color("var(--panel)")
    static let border = Color("var(--border)")
    static let muted = Color("var(--muted)")
    static let activeTint = Color("var(--active-tint)")
}
```
