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
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Maak websites met Swift.")
                .font(.heroTitle)
                .foregroundStyle(.primary)

            TabBar(selection: PortfolioTab.info) {
                Tab("Info", value: PortfolioTab.info)
                Tab("Persoonlijk", value: PortfolioTab.personal)
                Tab("Contact", value: PortfolioTab.contact)
            }

            Link("Neem contact op", destination: "#contact")
                .buttonStyle(.primary)
        }
        .padding(24)
    }
}

let rendered = HTMLRenderer().renderView(PortfolioPreview())
let document = WebDocument(
    title: "Portfolio",
    renderedView: rendered,
    stylesheetPath: "styles.css"
)

let html = document.htmlString(prettyPrinted: false)
let css = rendered.cssString(prettyPrinted: false)
```

`TabBar` is static-first today. `TabBar(selection:)` renders the selected tab with accessible tab semantics and generated SwiftCSS resources. A `Binding` initializer exists for render compatibility, but client-side tab switching is planned for the future client-state runtime.
