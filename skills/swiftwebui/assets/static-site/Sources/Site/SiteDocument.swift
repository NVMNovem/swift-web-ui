import SwiftWebUIStatic

/// Renders one page to a complete HTML document.
enum SiteDocument {

    static func html(for page: Page) -> String {
        let rendered = HTMLRenderer().renderView(PageView(page: page))

        // Only pages using binding-backed controls (a `TabView(selection: $tab)`)
        // produce JavaScript; it is small, so it rides in the document.
        let script = rendered.jsString(prettyPrinted: false)

        let document = WebDocument(
            title: page == .home ? page.title : "\(page.title) · Site",
            meta: [
                .charset("utf-8"),
                .viewport,
                .name("description", content: page.summary),
            ],
            renderedView: rendered,
            // The hand-written stylesheet, shared by every page.
            stylesheetPath: "/styles.css",
            language: "en",
            stylesheetLinkPolicy: .always,
            // The CSS generated from this page's modifiers goes inline: it
            // differs per page, and a second file would delay first paint.
            renderedStyleDelivery: .inline,
            bodyScripts: script.isEmpty ? [] : [.inline(script)]
        )

        // Not pretty-printed: indentation puts a line break between inline
        // elements, which a browser shows as a stray space.
        return document.htmlString(prettyPrinted: false) + "\n"
    }
}
