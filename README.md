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
                Article {
                    Link(destination: "https://example.com/project") {
                        Image("assets/profile1.jpeg", alt: "Project preview")
                            .width(Length("100%"))

                        VStack(alignment: .leading, spacing: .px(8)) {
                            Text("Reusable layout")
                                .semanticRole(.h2)

                            Text("Semantic HTML and SwiftCSS-backed styling.")
                                .semanticRole(.p)
                                .foregroundStyle(.muted)
                        }
                    }
                    .class("project-card")
                }
                .class("portfolio-item")
                .attribute("data-timeline-date", "2026-06")
            }
            .class("profile-summary")

            TabView(selection: $selectedTab) {
                Tab("Info", value: PortfolioTab.info) {
                    Text("Profile summary")
                        .semanticRole(.p)
                }
                Tab("Persoonlijk", value: PortfolioTab.personal) {
                    Text("Personal details")
                        .semanticRole(.p)
                }
                Tab("Contact", value: PortfolioTab.contact) {
                    Text("Contact options")
                        .semanticRole(.p)
                }
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

`TabBar` and `TabView` cover different tab-like controls. Use `TabBar` for selection-only controls such as navigation tabs, segmented controls, filters, and timeline selectors:

```swift
TabBar(selection: $selectedTab) {
    Tab("Info", value: PortfolioTab.info)
    Tab("Persoonlijk", value: PortfolioTab.personal)
    Tab("Contact", value: PortfolioTab.contact)
}
```

Use `TabView` when the component owns both the tab controls and the matching panels:

```swift
TabView(selection: $selectedTab) {
    Tab("Info", value: PortfolioTab.info) {
        Text("Profile summary")
    }
    Tab("Contact", value: PortfolioTab.contact) {
        Text("Contact options")
    }
}
```

`TabBar(selection: $state)`, `TabView(selection: $state)`, and `.set($state, to:)` generate HTML data attributes plus a small JavaScript resource for client-side state changes. Swift does not run in the browser, and `Button { selectedTab = ... }` closure translation is deferred.

Use `Group` for layout-neutral composition. An unmodified `Group` renders transparently with no wrapper; a modified `Group`, such as `Group { ... }.class("hero")`, renders an implicit `div` wrapper so the attributes and generated CSS class have an HTML element to attach to.

Use `VStack`, `HStack`, and `Grid` for layout intent. Use `Article` for self-contained semantic content such as cards, posts, projects, or timeline entries. Use `Div` only when you specifically want a low-level `div` escape hatch.

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

`Link("Title", destination:)` is shorthand for simple text links and renders direct anchor text. Use `Link(destination:) { ... }` when the anchor needs to wrap nested/card content:

```swift
Link(destination: "https://example.com") {
    Image("assets/project.jpeg", alt: "Project preview")
    VStack {
        Text("Project title")
        Text("Project description")
    }
}
.class("project-card")
.attribute("target", "_blank")
.attribute("rel", "noreferrer")
```

Use `Form`, `Label`, `Input`, and `TextArea` for static browser form markup. Typed form attributes are intentionally deferred; use `.attribute(_:_:)` for generic HTML attributes:

```swift
Form {
    Label("Name")
        .attribute("for", "contact-name")

    Input()
        .id("contact-name")
        .attribute("type", "text")
        .attribute("name", "name")
        .attribute("autocomplete", "name")
        .attribute("required", "")

    Label { Text("Message") }
        .attribute("for", "contact-message")

    TextArea()
        .id("contact-message")
        .attribute("name", "message")
        .attribute("required", "")

    Button("Send")
        .attribute("type", "submit")
}
.attribute("action", "mailto:hello@example.com")
.attribute("method", "post")
.attribute("enctype", "text/plain")
```

`Footer` renders semantic footer content:

```swift
Footer {
    Text("Copyright 2026")
        .semanticRole(.p)
}
.class("site-footer")
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
