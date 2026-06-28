# SwiftWebUI

SwiftWebUI is a SwiftUI-like view DSL for rendering browser UI to HTML and CSS resources. SwiftHTML owns HTML rendering, SwiftCSS owns CSS rendering, and SwiftWebUI keeps the component and modifier APIs at the web UI layer.

## Example

```swift
import SwiftWebUI

enum PortfolioTab: String, CaseIterable {
    case info
    case personal
    case contact
}

struct PortfolioPreview: View {
    @State private var selectedTab = PortfolioTab.info

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Group {
                Text("Maak websites met Swift.")
                    .semanticRole(.h1)
                    .font(.heroTitle)
                    .foregroundStyle(.primary)

                Text("Static HTML and extracted CSS from a Swift view tree.")
                    .semanticRole(.p)
                    .foregroundStyle(.secondary)
            }

            TabBar(selection: $selectedTab) {
                Tab("Info", value: PortfolioTab.info)
                Tab("Persoonlijk", value: PortfolioTab.personal)
                Tab("Contact", value: PortfolioTab.contact)
            }

            Button("Toon contact")
                .set($selectedTab, to: .contact)
                .buttonStyle(.primary)
        }
        .padding(24)
    }
}

let rendered = HTMLRenderer().renderView(PortfolioPreview())
let document = WebDocument(
    title: "Portfolio",
    renderedView: rendered,
    stylesheetPath: "styles.css",
    scriptPath: "app.js"
)

let html = document.htmlString(prettyPrinted: false)
let css = rendered.cssString(prettyPrinted: false)
let js = rendered.jsString(prettyPrinted: false)
```

`TabBar(selection: $state)` and `.set($state, to:)` generate HTML data attributes plus a small JavaScript resource for client-side state changes. Swift does not run in the browser, and `Button { selectedTab = ... }` closure translation is deferred.

Use `Group` for layout-neutral composition. An unmodified `Group` renders transparently with no wrapper; a modified `Group`, such as `Group { ... }.class("hero")`, renders an implicit `div` wrapper so the attributes and generated CSS class have an HTML element to attach to.

Use `VStack` and `HStack` for layout intent. Use `Div` only when you specifically want a low-level `div` escape hatch.

Use `Text.semanticRole(_:)` for HTML meaning, such as `.h1` for the page heading or `.p` for paragraph copy. Use `.font(...)`, `.foregroundStyle(...)`, `.class(...)`, and other styling modifiers for visual presentation; font choices do not imply heading or paragraph elements.

Use `.attribute(_:_:)` as an escape hatch for valid HTML attributes that do not have typed SwiftWebUI modifiers yet. Prefer typed modifiers when available; `.attribute(_:_:)` is useful for `data-*`, ARIA, and other generic attributes.
