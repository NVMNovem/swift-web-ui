# Static sites with SwiftWebUIStatic

A static site is an executable Swift package that runs on the Mac at build time
and writes plain files. `assets/static-site/` is a working starter.

## Layout of the starter

```
Package.swift                  one executable target depending on SwiftWebUIStatic
Resources/styles.css           hand-written CSS; everything in Resources/ is copied to dist/
Scripts/build.sh               swift run -c release Site --output dist --resources Resources
Scripts/serve.sh               python3 -m http.server over dist/
Sources/Site/Site.swift        @main: writes every page, copies Resources/
Sources/Site/Page.swift        enum of pages: path, output file, title, description
Sources/Site/SiteDocument.swift  view → WebDocument → HTML string
Sources/Site/Design/Theme.swift  colour and measure tokens
Sources/Site/Views/            PageView (switch over Page), SiteLayout, one view per page
```

`import SwiftWebUIStatic` is the only import a view file needs; it re-exports
`SwiftWebUI` and `SwiftCSS`. `import SwiftHTML` is needed only where a file
builds raw head or body nodes (below).

## Adding a page

1. Add a case to `Page` with its `path`, `title` and `summary`.
2. Write its view under `Views/`.
3. Add the case to the `switch` in `PageView`.

Pages are written as `about/index.html`, so `/about` works on any static host
without rewrite rules. Link between pages with `Link("About", destination:
Page.about.path)` rather than a string literal, so a renamed path cannot leave a
dead link.

For many similar pages (blog posts, products), keep the fixed pages in the enum
and add a second loop in `Site.swift` over the data, rendering a view per item to
its own `outputPath`. `SiteDocument` then takes a title, description and view
rather than a `Page`.

## The rendering pipeline

```swift
let rendered = HTMLRenderer().renderView(SomeView())   // RenderedView
rendered.htmlString()   // the body markup
rendered.cssString()    // generated classes for every modifier used
rendered.jsString()     // empty unless the view uses binding-backed tabs or RemoteList

let document = WebDocument(title: "…", renderedView: rendered, …)
document.htmlString(prettyPrinted: false)
```

Modifiers do not become inline styles in static output: each distinct set of
declarations becomes a generated class (`.swui-…`) in `cssString()`. That CSS
has to reach the page, either inline in the document or as a file.

### WebDocument parameters

| Parameter | Default | Use |
|---|---|---|
| `title` | `nil` | `<title>`. Falls back to the view's `.navigationTitle(_:)`. |
| `meta` | charset + viewport | `[.charset("utf-8"), .viewport, .name("description", content: …), .property("og:title", content: …)]` |
| `stylesheetPath` | `"styles.css"` | `href` of the stylesheet link. Use a rooted path (`"/styles.css"`) on a multi-page site. |
| `stylesheetLinkPolicy` | `.automatic` | `.always` to link a hand-written stylesheet regardless of generated CSS. |
| `renderedStyleDelivery` | `.stylesheet` | `.inline` puts the generated CSS in a `<style>` block. |
| `language` | `nil` | `<html lang>`. Set it. |
| `headNodes` | `[]` | Raw `SwiftHTML.HTMLNode`s for what `MetaTag` cannot express: `<link rel="icon">`, canonical, preloads. |
| `scriptPath` | `nil` | `src` of a script tag, emitted only when the view generated JavaScript. |
| `headScripts` / `bodyScripts` | `[]` | `WebScript.inline(js)`, `.module(js)`, `.importMap(json)`, `.source(…)`. |
| `bodyPrefixNodes` / `bodySuffixNodes` | `[]` | Raw nodes around the rendered view. |

The starter's arrangement — and the recommended one for a multi-page site — is
`stylesheetPath: "/styles.css"`, `stylesheetLinkPolicy: .always`,
`renderedStyleDelivery: .inline`: one shared hand-written stylesheet that the
browser caches, and each page's generated CSS inline so nothing blocks first
paint. The inline block comes after the link, which is why a stylesheet rule
needs `!important` to override a modifier.

Render with `prettyPrinted: false`. Pretty-printing breaks lines between inline
elements, and a browser shows each break as a space ("Hello , world").

A raw head node:

```swift
import SwiftHTML

let icon: SwiftHTML.HTMLNode = .element(.init(
    tag: "link",
    attributes: [.init("rel", "icon"), .init("href", "/icon.svg"), .init("type", "image/svg+xml")],
    children: [],
    isVoid: true
))
```

For a favicon and title alone, the view modifiers are simpler:
`.navigationTitle("Projects")` and `.navigationIcon(.url("/icon.svg"))` or
`.navigationIcon(.svg("<svg …>"))`.

### PreviewExporter

`try PreviewExporter.export(document, to: folderURL)` writes `index.html` plus
the stylesheet and script at the document's paths. It is the quickest route for
a **single-page** site. On a multi-page site every page would overwrite the same
`styles.css`, which is why the starter writes files itself.

## Resources

SwiftWebUI never touches the filesystem on the site's behalf. `Image("/images/hero.jpg", alt: "…")`
emits that string as `src` and nothing more. Put images, fonts, `robots.txt`,
favicons and the stylesheet in `Resources/`; the starter copies the whole
directory into `dist/` preserving paths. Use rooted paths (`/images/…`) so they
resolve from pages at any depth.

Give every `Image` real `alt` text, or `alt: ""` when it is decoration, and a
`width`/`height` or `aspectRatio` so the page does not jump as it loads.

## What is interactive in a static site

The page is rendered once, so `@State` holds only its initial value and `Button`
closures never run. What does work:

- **Links and native HTML behaviour**: `<a>`, `<form method="post" action="…">`
  submitting to a server, `<details>` via `Element("details")`, anchors
  (`.id("pricing")` + `Link("Pricing", destination: "#pricing")`).
- **Tabs.** `TabView(selection: $tab) { Tab("Details", value: .details) { … } }`
  with a `@State` binding emits a small generated script that switches panels.
  That script is in `rendered.jsString()`; the starter already inlines it when
  present. With a plain value (`selection: ProductTab.details`) the tabs are
  rendered in that state and do not switch.
- **`RemoteList`**: a list filled in the browser from a JSON array.

  ```swift
  Template("product-card") {
      Article {
          Text("").bindText("name")
          Link(destination: "#") { Text("View") }.bindAttribute("href", "url")
      }
  }
  RemoteList(source: .get("/api/products"), template: "product-card")
      .loading { Text("Loading…") }
      .empty { Text("Nothing here yet.") }
      .error { Text("Could not load.") }
  ```

  Field names may be dot paths (`category.name`). It fetches one GET endpoint
  returning an array; it is not a general data layer.
- **CSS-only effects** from the stylesheet: `:hover`, transitions, `@keyframes`.

Not available statically: `.sheet` and modal `Dialog` (omitted from the output),
`.onKeyDown`, `.transition(enter:exit:…)` exits, table sorting on click, anything
driven by a closure. If the site needs those, that page is a runtime app.

A small amount of hand-written JavaScript is a legitimate tool for a static
site: put it in `Resources/` and reference it with `headScripts`/`bodyScripts`.

## Forms

```swift
Form {
    Label("Email").attribute("for", "email")
    Input()
        .id("email")
        .attribute("type", "email")
        .attribute("name", "email")
        .attribute("autocomplete", "email")
        .attribute("required", "")
    TextArea().attribute("name", "message")
    Button("Send").attribute("type", "submit").buttonStyle(.primary)
}
.attribute("method", "post")
.attribute("action", "https://example.com/contact")
```

SwiftWebUI renders the markup; submission and validation are the browser's and
the server's.

## Building, previewing, deploying

```bash
./Scripts/build.sh     # writes dist/
./Scripts/serve.sh     # http://127.0.0.1:8080/
```

`dist/` is the deployable artefact: upload it to any static host (Cloudflare
Pages or Workers static assets, Netlify, GitHub Pages, S3). `404.html` at the
root is the name most hosts look for. Nothing about the output is tied to a host.

Because the site is ordinary Swift, it can be tested: a test target depending on
the executable can render every page and assert that each internal `href` names
a page that exists.
