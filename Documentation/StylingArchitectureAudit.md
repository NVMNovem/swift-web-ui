# Styling Architecture Audit

## Boundary

SwiftCSS owns raw CSS:

- `CSSProperty` types such as `Border`, `Padding`, `Gap`, `Display`, `BackgroundColor`, `BorderRadius`, `Width`, and `Height`.
- `CSSValue` types such as `CSSColor`, `CSSLength`, and property-specific value objects.
- CSS rendering and low-level escape hatches such as `RawProperty`.

SwiftWebUI owns the view DSL:

- View and modifier data.
- Semantic design tokens and UI-facing style values.
- Lowering UI abstractions into SwiftCSS properties during rendering.

SwiftWebUI may depend on SwiftCSS. SwiftCSS must not depend on SwiftWebUI.

## Duplicate Names

| Name | SwiftCSS responsibility | SwiftWebUI responsibility | Decision |
| --- | --- | --- | --- |
| `Border` | CSS `border` property. | Previously a string wrapper that immediately created `SwiftCSS.Border`. | Removed from SwiftWebUI. Border modifiers now store `SwiftCSS.Border` directly and expose string convenience overloads. |
| `Color` | CSS `color` property. | Semantic UI color token that lowers to `CSSColor` and then `SwiftCSS.Color` or `BackgroundColor`. | Keep in SwiftWebUI. The responsibilities differ, but unqualified use in rendering code should stay explicit as `SwiftCSS.Color` for CSS properties. |

## Duplicate Concepts

| Concept | SwiftCSS owner | SwiftWebUI owner | Decision |
| --- | --- | --- | --- |
| Background | `BackgroundColor` and raw `background` properties. | `Background`, a UI modifier value that can carry a semantic `Color` or raw background value. | Keep in SwiftWebUI as a modifier value. Rendering lowers it to `BackgroundColor` or `RawProperty("background", ...)`. |
| Shadow | `BoxShadow` CSS property. | No separate owner after this audit. | Removed the raw `Shadow` wrapper. The `.shadow(...)` modifier stores `BoxShadow` directly and keeps a string convenience overload. Add a future `ShadowStyle` only if it models semantic elevations, states, or typed shadow components. |
| Font | `FontSize`, `FontWeight`, `FontFamily`, and related CSS properties. | `Font`, a SwiftUI-like semantic visual styling API lowered into SwiftCSS declarations. | Keep `Font` in SwiftWebUI. It provides UI-level font roles and system font intent rather than duplicating CSS property rendering. |
| Padding | `Padding` CSS property and edge-specific raw properties. | `.padding(...)` modifier accepting SwiftWebUI `Length` and `Edge.Set`. | Keep modifier in SwiftWebUI; CSS property remains SwiftCSS. Edge expansion happens at render lowering. |
| Gap | `Gap` CSS property. | `.gap(...)` modifier and stack spacing values. | Keep modifier in SwiftWebUI; rendered property remains SwiftCSS `Gap`. |
| Alignment | Flex alignment values such as `AlignItemsValue`. | `Alignment` enum for stack APIs. | Keep in SwiftWebUI. It is a view-layout abstraction lowered to SwiftCSS flex alignment values. |
| Length | `CSSLength` raw CSS value. | `Length`, integer/float literal friendly UI DSL length. | Keep in SwiftWebUI. It gives view modifiers a compact API and lowers to `CSSLength`. |
| Radius | `BorderRadius` CSS property. | `.cornerRadius(...)` modifier using `Length`. | Do not add a SwiftWebUI `Radius` wrapper unless semantic radius tokens are needed. |
| Frame | `Width`, `Height`, and `MaxWidth` CSS properties. | `.frame(width:height:maxWidth:)` modifier. | Keep frame as SwiftWebUI layout DSL; render to SwiftCSS size properties. |

## Current Rule

Do not add SwiftWebUI types that only store a CSS string and immediately return a same-meaning SwiftCSS property. Use the SwiftCSS property directly in modifier storage, with SwiftWebUI convenience overloads where that keeps the view DSL pleasant.

Add a SwiftWebUI style type only when it provides UI semantics, such as named tokens, state-aware styling, multiple CSS declarations, typed components, or design-system concepts.
