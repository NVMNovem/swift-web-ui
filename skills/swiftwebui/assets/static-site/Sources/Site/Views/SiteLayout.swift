import SwiftWebUIStatic

/// The frame every page sits in: header, the page's `<main>`, footer.
struct SiteLayout<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Div {
            // SwiftWebUI has no Header, Nav or Main view; Element names the tag.
            Element("header") {
                HStack(alignment: .center, spacing: .px(24)) {
                    Link(destination: Page.home.path) {
                        Text("Site").font(.system(size: 20, weight: .semibold))
                    }
                    .foregroundStyle(Theme.text)
                    .textDecoration(.none)

                    Spacer()

                    Element("nav") {
                        HStack(spacing: .px(20)) {
                            Link("Home", destination: Page.home.path)
                            Link("About", destination: Page.about.path)
                        }
                    }
                    .attribute("aria-label", "Main")
                }
            }
            .padding(.vertical, .px(20))
            .border(.bottom, "1px solid var(--site-border)")

            Element("main") {
                content
            }
            .padding(.vertical, .px(48))

            Footer {
                Text("Built with SwiftWebUI.")
                    .semanticRole(.p)
                    .font(.footnote)
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(.vertical, .px(24))
            .border(.top, "1px solid var(--site-border)")
        }
        .maxWidth(Theme.column)
        .margin(.horizontal, .auto)
        .padding(.horizontal, Theme.gutter)
    }
}
