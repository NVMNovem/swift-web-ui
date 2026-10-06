# SwiftWebUI API map

What exists as of swift-web-ui 1.2.0, and what to use in place of the SwiftUI
API that does not. The package's own source is the authority; when this file and
the source disagree, the source is right:

- views: `.build/checkouts/swift-web-ui/Sources/SwiftWebUI/Backend/Models/Views/`
- modifiers: `…/SwiftWebUI/Backend/Extensions/View/View+Modifiers.swift`
- guides: `…/SwiftWebUI/SwiftWebUI.docc/*.md`

Contents: [Not in SwiftWebUI](#not-in-swiftwebui) · [Views](#views) ·
[Values](#values) · [Modifiers](#modifiers) · [Recipes](#recipes)

## Not in SwiftWebUI

| SwiftUI | Use instead |
|---|---|
| `List`, `LazyVStack`, `ScrollView` | `VStack` + `ForEach`; for real list markup `Element("ul") { ForEach(items) { item in Element("li") { … } } }`. The page scrolls; for a scrolling region, `.overflow(.auto)` with a `maxHeight`. |
| `LazyVGrid`, `GridRow` | `Grid(spacing:) { … }.gridTemplateColumns("repeat(3, minmax(0, 1fr))")` |
| `NavigationStack`, `NavigationLink`, `.navigationDestination` | `Link(_:destination:)` between pages. `.navigationTitle(_:)` exists but sets the browser tab title. |
| `TextField`, `SecureField`, `TextEditor` | `Input().attribute("type", "text")`, `TextArea()` — no value binding (see runtime-app.md, "Reading inputs") |
| `Toggle`, `Picker`, `Slider`, `Stepper`, `DatePicker` | `Input().attribute("type", "checkbox" / "range" / "date")`; `Element("select") { Element("option") { Text("A") } }`; or buttons and state |
| `Divider` | `Element("hr")`, or `.border(.bottom, "1px solid …")` on the row above |
| `Color.red`, `.primary`, `Color(.systemBackground)` | `Color("#d00")`, `Color("var(--token)")` |
| `Image(systemName:)`, asset catalogues | `Image("/icons/x.svg", alt: "")` with the file in `Resources/` |
| `AsyncImage` | `Image(url, alt:)` — the browser loads it; add `.attribute("loading", "lazy")` |
| `AnyView` | `if`/`switch` in a builder; a function returning `some View` |
| `GeometryReader`, `.frame(maxWidth: .infinity)`, `.fixedSize` | `.width(.percent(100))`, `.flexGrow(1)`, `.maxWidth(_:)`, `.aspectRatio(_:)` |
| `.padding()` (no argument), `.padding(16)` | `.padding(.px(16))`, `.padding(.horizontal, .px(16))` |
| `.fontWeight(_:)`, `.italic()` | `.font(.system(size:weight:))`, `.bold()`; italic via a class |
| `.foregroundColor`, `.tint` | `.foregroundStyle(Color)` |
| `.hidden()`, `.disabled(_:)` | conditionally include the view; `.attribute("disabled", "")` |
| `.onTapGesture` | `Button { … }` (runtime), `Link` |
| `.task`, `.onAppear`, `.onChange` | start work from `main()`; see runtime-app.md |
| `.animation`, `withAnimation` | `.transition("opacity 200ms ease")` (CSS), `.transition(enter:exit:durationMilliseconds:)`, `@keyframes` in the stylesheet |
| `@Binding`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject` | a `Binding<T>` stored property; `@Observable` classes with `@Environment(Type.self)` |
| `.environment(\.key, value)`, `@Environment(\.colorScheme)` | CSS custom properties, which inherit through the DOM; `@media (prefers-color-scheme)` |
| `Header`, `Nav`, `Main` views | `Element("header")`, `Element("nav")`, `Element("main")` |
| size classes, `ViewThatFits` | a class and an `@media` rule in the stylesheet |
| `.alert`, `.popover`, `.confirmationDialog` | `.sheet(isPresented:)` (runtime only) |

## Views

```swift
// Text and media
Text("Title").semanticRole(.h1)                 // roles: span (default), p, h1…h6
Image("/images/cover.jpg", alt: "Cover")
Link("Docs", destination: "/docs")
Link(destination: "/project") { Article { … } }  // a link wrapping content

// Layout
VStack(alignment: .leading, spacing: .px(16)) { … }   // alignment defaults to .center
HStack(alignment: .center, spacing: .px(8)) { … }
ZStack(alignment: .topTrailing) { … }                 // children share one box
Grid(spacing: .px(12)) { … }                          // display: grid; add .gridTemplateColumns
Spacer()                                              // flexible space in a stack
Group { … }                                           // no element unless modified

// Semantic containers
Article { … }   Section { … }   Footer { … }   Form { … }   Div { … }
Element("nav") { … }       // any other tag
Element("hr")              // a leaf

// Controls
Button("Save") { save() }                         // closure runs in a runtime app only
Button(action: save) { HStack { Image(…); Text("Save") } }
Label("Email").attribute("for", "email")
Input().id("email").attribute("type", "email")
TextArea().attribute("name", "message")

// Collections
ForEach(items) { item in Row(item) }              // every row the same concrete type
ForEach(items, id: { $0.sku }) { item in … }      // keyed; needed when rows own state

// Tabs — Value is String, Int, Bool, or an enum with a String or Int raw value
TabView(selection: $tab) {                        // controls and panels
    Tab("Details", value: .details) { Text("…") }
    Tab("Reviews", value: .reviews) { Text("…") }
}
TabBar(selection: $tab) { Tab("Home", value: .home); Tab("About", value: .about) }   // controls only

// Tables
Table(products, id: { $0.id }, sort: $sort) {     // @State var sort = TableSort("Name")
    TableColumn("Name", value: { $0.name })
    TableColumn("Price", width: .px(96), alignment: .trailing, value: { $0.cents }) { p in
        Text(p.formattedPrice)
    }
    TableColumn("Actions") { p in Link("Open", destination: p.url) }   // not sortable
}
.stickyHeader()
.rowBackground { $0.isFeatured ? Background(Theme.surface) : nil }
// also .headerHidden(), .columnLayout(.fixed / .sizedToContent)

// Presentation (runtime only)
someView.sheet(isPresented: $shown) { … }
Dialog(isPresented: $shown, isModal: false) { … }

// Layering
Image(…).overlay(alignment: .top) { Text("New") }
content.background(alignment: .center) { Image(…) }

// Static-only (import SwiftWebUIStatic)
Template("card") { … }   RemoteList(source: .get("/api/items"), template: "card")
```

A `Table` renders real `table` markup with a plain default look; modifiers on it
apply to the `table` element. Classes for stylesheet rules such as row hover:
`swiftwebui-table`, `-header`, `-header-cell`, `-sort`, `-sort-indicator`,
`-row`, `-cell`.

## Values

```swift
// Length (SwiftCSS)
.px(16)  .percent(50)  .em(1.5)  .rem(1)  .vh(100)  .vw(50)  .ch(60)  .fr(1)  .zero  .auto
Length("clamp(1rem, 4vw, 3rem)")          // anything else, as CSS; string literals also work

// Color (SwiftCSS)
Color("#0a66d8")  Color("rgb(0 0 0 / 0.5)")  Color("var(--accent)")

// Font — size is in px
.largeTitle(34) .title(28) .title2(22) .title3(20) .headline(17, semibold)
.body(17) .callout(16) .subheadline(15) .footnote(13) .caption(12) .caption2(11)
Font.system(size: 44, weight: .bold, design: .serif)
// weights: ultraLight thin light regular medium semibold bold heavy black .weight(650)
// designs: default serif rounded monospaced — there is no custom family; set
//          font-family on body (or a class) in the stylesheet

// Edges and alignment
Edge.Set: .top .bottom .leading .trailing .horizontal .vertical .all
Alignment: .leading .center .trailing .top .bottom .topLeading .topTrailing .bottomLeading .bottomTrailing
TextAlignment: .leading .center .trailing .justified

// Buttons
.buttonStyle(.primary)   .buttonStyle(.secondary)     // black/white pills
ButtonStyleToken(className: "button accent", declarations: [
    Padding("10px 18px").cssDeclaration,
    BackgroundColor(Color("var(--accent)")).cssDeclaration,
    BorderRadius(.px(10)).cssDeclaration,
])
```

`.buttonStyle` works on a `Link` as well, which is how a call-to-action that
navigates is made. A `Button` without a style is the browser's default button;
reset it in the stylesheet (`button { font: inherit; }`).

## Modifiers

Every modifier is available on every view. Arguments are SwiftCSS value types
(`.flex`, `.hidden`, `.pointer`, …) unless shown as a string.

**Identity and attributes** — `.id("x")` `.class("a b")` `.attribute("name", "value")`

**Document** — `.navigationTitle("…")` `.navigationIcon(.svg("<svg…>") / .url("/icon.svg"))`

**Spacing and size**
- `.padding(_:)` `.padding(edges, _:)` `.margin(_:)` `.margin(edges, _:)`
- `.frame(width:height:maxWidth:)` `.width` `.minWidth` `.maxWidth` `.height` `.minHeight` `.maxHeight`
- `.aspectRatio(16, 9)` `.aspectRatio(1.5)`

**Layout**
- `.display(.flex / .grid / .block / .inlineFlex / .none …)`
- `.justifyContent(_:)` `.alignItems(_:)` `.alignSelf(_:)` `.flexWrap(.wrap)` `.gap(_:)`
- `.flexGrow(1)` `.flexShrink(0)` `.flexBasis(_:)`
- `.gridTemplateColumns("…")`
- `.position(.relative / .absolute / .fixed / .sticky)` `.top` `.right` `.bottom` `.left`
  `.inset(.zero)` `.inset(.vertical, .px(12))` `.zIndex(10)`
- `.overflow(.hidden / .auto / .scroll)` `.scrollMarginTop(_:)` `.scrollbarWidth(.none / .thin)`

There is no `flexDirection` modifier: an `HStack` is a row and a `VStack` a
column. To switch direction at a breakpoint, use a class and the stylesheet.

**Text**
- `.font(_:)` `.bold()` `.foregroundStyle(_:)`
- `.lineHeight(.multiple(1.5) / .length(.px(28)) / .normal)` `.letterSpacing(_:)`
- `.textAlign(_:)` `.textTransform(.uppercase)` `.textDecoration(.none / .underline)`
- `.lineLimit(2)` `.lineLimit(2, reservesSpace: true)` `.lineLimit(1...3)` — sets
  `display` and `overflow` itself; do not follow it with those on the same view
- `.whiteSpace(.nowrap)` `.overflow(.hidden)` `.textOverflow(.ellipsis)` — one-line truncation needs all three
- `.wordBreak(_:)`

**Surface**
- `.background(Color)` `.background("linear-gradient(…)")`
- `.border(width: .px(1), color: c)` `.border(width:style:color:)` `.border("1px solid #eee")` `.border(.bottom, "1px solid #eee")`
- `.cornerRadius(.px(12))` `.clipShape(.capsule)`
- `.shadow("0 8px 24px rgba(0,0,0,0.12)")` `.opacity(0.6)` `.backdropFilter("blur(18px)")`
- `.objectFit(.cover)` `.objectPosition("center")` — for images

**Behaviour**
- `.cursor(.pointer)` `.pointerEvents(.none)` `.outline(.none)` `.resize(.vertical)`
- `.transform("translateY(-2px)")` `.transition("opacity 200ms ease")`
- runtime only: `.defaultFocus()` `.onKeyDown("Enter") { … }`
  `.transition(enter:exit:durationMilliseconds:)` `.sheet(isPresented:content:)`
- environment: `.environment(object)`

Modifier order rarely matters, unlike SwiftUI: consecutive modifiers on one
view become declarations on **one element**, not nested wrappers. So
`.padding(…).background(…)` and `.background(…).padding(…)` are the same box
with a background and padding. To get padding outside a background, nest a
container. The exception is the layering pair `.overlay { }` / `.background { }`
with a closure, which wraps the view in a `ZStack`.

## Recipes

**Centred page column**

```swift
Div { content }
    .maxWidth(.px(960))
    .margin(.horizontal, .auto)
    .padding(.horizontal, .px(20))
```

**Card grid that reflows without a breakpoint**

```swift
Grid(spacing: .px(16)) {
    ForEach(items) { item in Card(item: item) }
}
.gridTemplateColumns("repeat(auto-fit, minmax(240px, 1fr))")
```

**Header with navigation**

```swift
Element("header") {
    HStack(alignment: .center, spacing: .px(24)) {
        Link(destination: "/") { Text("Brand").font(.headline) }
        Spacer()
        Element("nav") {
            HStack(spacing: .px(20)) {
                Link("Pricing", destination: "/pricing")
                Link("Docs", destination: "/docs")
            }
        }
        .attribute("aria-label", "Main")
    }
    .flexWrap(.wrap)
}
```

**Hero image with text over it**

```swift
Image("/images/hero.jpg", alt: "")
    .width(.percent(100))
    .aspectRatio(21, 9)
    .objectFit(.cover)
    .overlay(alignment: .bottomLeading) {
        Text("Headline").semanticRole(.h1).font(.largeTitle).padding(.px(24))
    }
```

**Sticky header**

```swift
Element("header") { … }
    .position(.sticky)
    .top(.zero)
    .zIndex(10)
    .background(Theme.background)
```

**A component with content**

```swift
struct Card<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: .px(12)) {
                Text(title).semanticRole(.h2).font(.title3)
                content
            }
        }
        .padding(.px(20))
        .background(Theme.surface)
        .cornerRadius(.px(14))
    }
}
```

**A reusable style**

```swift
extension View {
    func cardSurface() -> some View {
        self.padding(.px(20)).background(Theme.surface).cornerRadius(.px(14))
    }
}
```

**Hover and focus** — a class on the view, the rule in the stylesheet:

```swift
Link("Read", destination: "/post").class("site-link")
```

```css
.site-link:hover { text-decoration: underline; }
```

**External link**

```swift
Link("GitHub", destination: "https://github.com/…")
    .attribute("target", "_blank")
    .attribute("rel", "noreferrer")
```
