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

extension Color {
    static let panel = Color("var(--panel)")
    static let border = Color("var(--border)")
    static let muted = Color("var(--muted)")
    static let primary = Color("var(--primary)")
}

struct PortfolioPreview: View {
    @State private var selectedTab = PortfolioTab.info

    var body: some View {
        VStack(alignment: .leading, spacing: .px(24)) {
            Group {
                Text("Maak websites met Swift.")
                    .semanticRole(.h1)
                    .display(.block)
                    .margin(.bottom, .px(5))
                    .font(.largeTitle)
                    .foregroundStyle(.primary)

                Text("Static HTML and extracted CSS from a Swift view tree.")
                    .semanticRole(.p)
                    .foregroundStyle(.muted)
            }

            Grid(spacing: .px(16)) {
                Image("assets/profile1.jpeg", alt: "Profile")
                    .margin(.top, .px(24))
                    .width(Length("100%"))
                    .maxWidth(.px(380))

                Text("Reusable layout, semantic HTML, and SwiftCSS-backed styling.")
                    .semanticRole(.p)
                    .background(.panel)
                    .border(width: .px(1), color: .border)
                    .cornerRadius(.px(17))
            }
            .class("profile-summary")

            TabBar(selection: $selectedTab) {
                Tab("Info", value: PortfolioTab.info)
                Tab("Persoonlijk", value: PortfolioTab.personal)
                Tab("Contact", value: PortfolioTab.contact)
            }

            Button("Toon contact")
                .set($selectedTab, to: .contact)
                .buttonStyle(.primary)
        }
        .padding(.px(24))
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

Use `VStack`, `HStack`, and `Grid` for layout intent. Use `Div` only when you specifically want a low-level `div` escape hatch.

Sizing modifiers such as `.width(...)`, `.minWidth(...)`, `.maxWidth(...)`, `.height(...)`, `.minHeight(...)`, and `.maxHeight(...)` are generic view modifiers. They apply to all rendered views, including `Image`, and lower through SwiftCSS-backed generated classes.

Display and margin modifiers are generic view modifiers. Use `.display(...)` for CSS display values such as `.block`, `.flex`, and `.grid`; use `.margin(...)` for CSS margins such as `.margin(.bottom, .px(5))`, `.margin(.horizontal, .px(16))`, and `.margin(.all, .px(20))`. `.padding(...)` follows SwiftWebUI edge semantics, while `.margin(...)` maps directly to CSS margins.

Use `Text.semanticRole(_:)` for HTML meaning, such as `.h1` for the page heading or `.p` for paragraph copy. Use `.font(.largeTitle)`, `.font(.system(size:weight:design:))`, `.foregroundStyle(...)`, `.class(...)`, and other styling modifiers for visual presentation; font choices do not imply heading or paragraph elements, and semantic roles do not imply visual font styling.

Typography modifiers are generic view modifiers. `semanticRole` controls HTML semantics; `.letterSpacing(...)`, `.textTransform(...)`, `.lineHeight(...)`, `.textAlign(...)`, and `.textDecoration(...)` control visual presentation and lower through SwiftCSS-backed declarations.

```swift
Text("Eyebrow")
    .font(.caption)
    .letterSpacing(.em(0.1))
    .textTransform(.uppercase)

Text("Paragraph")
    .lineHeight(.em(1.5))
    .textAlign(.center)

Link("Website", destination: "https://example.com")
    .textDecoration(.underline)
```

SwiftWebUI re-exports SwiftCSS, so downstream users can write `import SwiftWebUI` and use SwiftCSS value types such as `Length`, `Color`, `Angle`, `Percentage`, and `Time` without a separate `import SwiftCSS`. SwiftWebUI no longer defines its own `Color` or `Length`.

Prefer typed visual modifiers for common styling: `.background(Color("var(--panel)"))`, `.foregroundStyle(Color("var(--muted)"))`, and `.border(width: .px(1), color: Color("var(--border)"))` lower to SwiftCSS-backed declarations. Apps and sites should define their own design tokens by extending SwiftCSS `Color` in their own module, for example:

```swift
extension Color {
    static let panel = Color("var(--panel)")
    static let border = Color("var(--border)")
    static let muted = Color("var(--muted)")
    static let activeTint = Color("var(--active-tint)")
}
```

Raw string overloads such as `.background("linear-gradient(...)")` and `.border("1px solid currentColor")` remain available as low-level CSS escape hatches.

Use `.attribute(_:_:)` as an escape hatch for valid HTML attributes that do not have typed SwiftWebUI modifiers yet. Prefer typed modifiers when available; `.attribute(_:_:)` is useful for `data-*`, ARIA, and other generic attributes.
