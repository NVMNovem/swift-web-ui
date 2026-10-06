---
name: swiftwebui
description: Build websites and web apps in Swift with SwiftWebUI (the NVMNovem/swift-web-ui package) — static sites rendered to HTML/CSS at build time, and interactive apps compiled to WebAssembly. Use this whenever a task involves SwiftWebUI, SwiftWebUIStatic or SwiftWebUIRuntime, a Package.swift that depends on swift-web-ui, or a request to make a website, landing page, marketing site, dashboard or web app "in Swift", "with SwiftUI-style code" or "like SwiftUI for the web" — including starting a new site from scratch, adding pages or components to an existing one, styling, and building or serving it. SwiftWebUI looks like SwiftUI but is a different, much smaller library, so read this before writing any view code rather than relying on SwiftUI knowledge.
---

# Building websites with SwiftWebUI

SwiftWebUI is a Swift package for writing web UI the way SwiftUI is written:
`struct HomeView: View { var body: some View { VStack { Text("Hi") } } }`. Views
lower to ordinary HTML elements and CSS declarations — there is no canvas, no
layout engine and no virtual DOM framework underneath.

Two things make it easy to get wrong:

- **It is not SwiftUI.** The names match where SwiftUI has the concept, but the
  surface is far smaller and partly web-shaped. `List`, `NavigationStack`,
  `TextField`, `Toggle`, `ScrollView`, `.task`, `.onAppear`, `.onTapGesture`,
  `AnyView` and many more do not exist. Code written from SwiftUI memory will
  not compile.
- **It is young and moving.** What exists is what the checked-out version's
  source says exists. When unsure whether an API is there, look instead of
  guessing: after the first build the source is in
  `.build/checkouts/swift-web-ui/Sources/` (start with
  `SwiftWebUI/Backend/Extensions/View/View+Modifiers.swift` for modifiers and
  `SwiftWebUI/Backend/Models/Views/` for views).

`references/api.md` is the map of what exists and what to use in place of the
SwiftUI API that does not. Read it before writing views.

## 1. Choose the kind of site

| | Static site | Runtime app |
|---|---|---|
| Module | `SwiftWebUIStatic` | `SwiftWebUI` + `SwiftWebUIRuntime` |
| Runs | on the Mac, at build time | in the browser, as WebAssembly |
| Output | HTML and CSS files | a `.wasm` bundle (≈1.5 MB gzipped minimum) + loader |
| `@State`, `Button { }` closures, `.sheet`, `.onKeyDown` | no — rendered once | yes |
| Readable without JavaScript, by crawlers, instantly | yes | no |
| Toolchain | any Swift 6.2+ | a WebAssembly Swift SDK and its exactly matching compiler |

Choose **static** for anything that is read: landing pages, marketing sites,
documentation, blogs, legal pages. It is the stable, recommended path, and it
still allows a little interactivity (tabs; lists fetched from a JSON API).

Choose **runtime** only when the page is an application — state that changes as
the visitor clicks, forms that talk to an API, sheets. The runtime is
experimental; say so to the user when recommending it.

If the user has not said and the request is a "website", build static. A site
can also be both: static pages plus one runtime app on its own page.

## 2. Start from the template

Do not write the project skeleton from memory — the build wiring is the part
that is not derivable from the API. Copy the matching starter and rename:

```bash
cp -R <this-skill>/assets/static-site <project-dir>     # or assets/runtime-app
```

Both starters have been built and run as they are. Then read the matching
reference for how the pieces fit and how to extend them:

- `references/static-site.md` — pages, the document, resources, deployment
- `references/runtime-app.md` — the Wasm build, toolchain, state, async work, inputs

Build and look at the result before changing anything, so that later failures
are known to be yours:

```bash
./Scripts/build.sh && ./Scripts/serve.sh
```

## 3. Write views

The shape is SwiftUI's: a `struct` conforming to `View` with a `body`, composed
from other views, with modifiers chained on. The rules that differ:

- **Text is a `span` unless told otherwise.** Give text its HTML meaning with
  `.semanticRole(.h1 … .h6, .p)`, and its look with `.font(_:)`. The two are
  independent; a heading without a role is not a heading to a screen reader or
  a search engine.
- **Lengths are CSS lengths.** `spacing: .px(16)`, `.padding(.px(24))`,
  `.maxWidth(.percent(100))`, `.margin(.horizontal, .auto)`. A bare number does
  not compile. `.padding()` with no argument does not exist.
- **Colours are CSS colours.** `Color("#1d1d1f")`, `Color("var(--accent)")`.
  There is no `.red`, `.primary` or asset catalogue. Define tokens once (see
  "Styling") and use those.
- **Use the semantic container that fits**: `Article`, `Section`, `Footer`,
  `Form`. For tags with no view of their own (`header`, `nav`, `main`, `aside`,
  `ul`/`li`, `svg`) use `Element("nav") { … }`. `Div` is the last resort.
- **A builder block holds at most 10 children.** Group more inside `Group`, a
  stack or a subview — which is better structure anyway.
- **There is no `AnyView`.** Branch with `if`/`switch` inside a builder, or
  write a function returning `some View`. `ForEach` needs every row to be the
  same concrete type, so a row that varies is a subview with the branch inside it.
- **Links navigate, buttons act.** `Link("About", destination: "/about")` is an
  `<a>`. A `Button` closure only runs in a runtime app.
- **Anything HTML has that SwiftWebUI has no modifier for** goes through
  `.attribute("name", "value")`, `.id(_:)` and `.class(_:)` — `aria-label`,
  `target`, `rel`, `type`, `placeholder`, `loading="lazy"`.

## 4. Style in the right place

Styling is split in two, and keeping to the split is what keeps a site
maintainable:

- **How an element looks is a modifier on its view** — padding, font, colour,
  border, radius, layout.
- **The stylesheet (`Resources/styles.css`) holds only what a modifier cannot
  say**: custom properties (the palette), at-rules (`@media` for dark mode and
  breakpoints, `@font-face`, `@keyframes`), and selectors (`:hover`,
  `:focus-visible`, element resets).

The bridge between them is CSS custom properties: declare `--site-accent` in the
stylesheet, expose it in Swift as `static let accent = Color("var(--site-accent)")`,
and views name what a colour is *for*. Dark mode is then one `@media` block
redeclaring the properties, and no view changes.

**Responsive layout** is the one place this leaks: a modifier cannot vary with
the viewport. Give the view a `.class("site-card-grid")` and write the breakpoint
in the stylesheet, with `!important`, because the modifier's own declaration
would otherwise win. Prefer layouts that need no breakpoint — `flexWrap(.wrap)`,
`gridTemplateColumns("repeat(auto-fit, minmax(240px, 1fr))")`, `maxWidth` — and
reach for a class only when those cannot do it.

Some modifiers take a raw CSS string because the CSS value is too broad to type
(`gridTemplateColumns`, `transform`, `transition`, `backdropFilter`, and string
overloads of `background`, `border`, `shadow`). That is intended. Prefer the
typed overload where there is one.

## 5. Verify by looking

A site that compiles can still be wrong. After each meaningful change, build,
serve and open the page in a browser; check it at a phone width as well as a
desktop one, and in dark mode if the stylesheet supports it. For a runtime app,
click through the interactions and check the browser console for errors.

For a static site, reading the generated HTML in `dist/` is a fast way to
confirm that headings are headings and links point where intended.

## 6. When SwiftWebUI cannot express something

It will happen; the library is deliberately small. In order of preference:

1. A lower-level modifier or `.attribute` that already exists (`references/api.md`).
2. A class plus a rule in the stylesheet, for anything involving a selector,
   pseudo-class or at-rule.
3. `Element("tag")` for a missing HTML element.
4. In a runtime app, a small JavaScriptKit bridge for browser APIs.

Do not fake a missing feature with JavaScript-measured layout or by generating
HTML strings. Tell the user what was missing and how it was worked around — the
library's maintainers treat such gaps as things to fix upstream in
`swift-web-ui`, `swift-css` or `swift-html`, and a silent workaround hides them.
