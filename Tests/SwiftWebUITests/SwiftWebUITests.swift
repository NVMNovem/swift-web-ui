import Testing
@testable import SwiftWebUI
import Foundation
import SwiftHTML

enum TimeLineNavigation: String, Sendable {
    case novem
    case funico
}

enum PortfolioTab: String, CaseIterable {
    case work
    case personal
    case contact
}

struct SwiftWebUIDummy: View {
    @State private var activeTimeline = TimeLineNavigation.novem
    
    init() {}
    
    var body: some View {
        VStack(spacing: 28) {
            Text("Maak websites met Swift.")
                .font(.heroTitle)
                .foregroundStyle(.primary)
            HStack(spacing: 12) {
                Link("Bekijk mijn werk", destination: "#work")
                    .buttonStyle(.primary)
                Link("Neem contact op", destination: "#contact")
                    .buttonStyle(.secondary)
                Button("Funico")
                    .buttonStyle(.secondary)
                    .setState("activeTimeline", to: TimeLineNavigation.funico.rawValue)
            }
        }
        .padding(24)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 15)
            .padding(.vertical, 5)
            .bold()
            .foregroundStyle(.white)
            .background(.accent)
            .clipShape(.capsule)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var myAppPrimaryButton: PrimaryButtonStyle { .init() }
}

@Test func rendersSimpleText() {
    let renderer = HTMLRenderer()
    let nodes = renderer.renderNodes(Text("Hello <Swift>"))
    let html = nodes.map { $0.render(prettyPrinted: false) }.joined()

    #expect(nodes.first is Span)
    #expect(html == "<span>Hello &lt;Swift&gt;</span>")
}

@Test func rendersNestedStacks() {
    let rendered = HTMLRenderer().renderView(
        VStack(spacing: 20) {
            Text("Top")
            HStack(spacing: 8) {
                Text("Left")
                Text("Right")
            }
        }
    )
    let html = rendered.htmlString()
    let css = rendered.cssString()

    #expect(html.contains("<div class=\"swui-1\">"))
    #expect(html.contains("<span>Top</span>"))
    #expect(html.contains("<div class=\"swui-2\">"))
    #expect(html.contains("<span>Left</span><span>Right</span>"))
    #expect(!html.contains("style="))
    #expect(css.contains(".swui-1"))
    #expect(css.contains("flex-direction: column"))
    #expect(css.contains("gap: 20px"))
    #expect(css.contains(".swui-2"))
    #expect(css.contains("flex-direction: row"))
    #expect(css.contains("gap: 8px"))
}

@Test func rendersStoredModifiers() {
    let rendered = HTMLRenderer().renderView(
        Text("Styled")
            .padding(.horizontal, 16)
            .frame(width: 320, height: nil, maxWidth: .percent(100))
            .background(.white)
            .foregroundStyle(.primary)
            .font(.heroTitle)
            .cornerRadius(12)
            .border("1px solid currentColor")
            .shadow("0 12px 40px rgba(0, 0, 0, 0.12)")
            .gap(10)
    )
    let html = rendered.htmlString()
    let css = rendered.cssString()

    #expect(html == "<span class=\"swui-1\">Styled</span>")
    #expect(!html.contains("style="))
    #expect(css.contains("padding-left: 16px"))
    #expect(css.contains("padding-right: 16px"))
    #expect(css.contains("width: 320px"))
    #expect(css.contains("max-width: 100%"))
    #expect(css.contains("background-color: #fff"))
    #expect(css.contains("color: var(--color-primary, #111827)"))
    #expect(css.contains("font-weight: 760"))
    #expect(css.contains("border-radius: 12px"))
    #expect(css.contains("border: 1px solid currentColor"))
    #expect(css.contains("box-shadow: 0 12px 40px rgba(0, 0, 0, 0.12)"))
    #expect(css.contains("gap: 10px"))
}

@Test func rendersClassAndIDModifiers() {
    let html = HTMLRenderer().render(
        Link("Work", destination: "#work")
            .class("button")
            .class("primary")
            .id("work-link")
    )

    #expect(html == "<a href=\"#work\" class=\"button primary\" id=\"work-link\">Work</a>")
}

@Test func renderViewReturnsContentAndResourcesSeparately() {
    let rendered = HTMLRenderer().renderView(
        Text("Hello")
            .foregroundStyle(.primary)
    )

    #expect(rendered.htmlString() == "<span class=\"swui-1\">Hello</span>")
    #expect(rendered.cssString().contains(".swui-1"))
    #expect(rendered.cssString().contains("color: var(--color-primary, #111827)"))
    #expect(rendered.jsString().isEmpty)
    #expect(rendered.resources.styles.count == 1)
    #expect(rendered.resources.scripts.isEmpty)
}

@Test func renderReturnsHTMLOnlyString() {
    let html = HTMLRenderer().render(
        Text("Hello")
            .foregroundStyle(.primary)
    )

    #expect(html == "<span class=\"swui-1\">Hello</span>")
    #expect(!html.contains("color: var(--color-primary, #111827)"))
}

@Test func preservesUserClassesWhenAddingGeneratedClass() {
    let rendered = HTMLRenderer().renderView(
        Link("Work", destination: "#work")
            .class("button primary")
            .padding(12)
    )

    #expect(rendered.htmlString() == "<a href=\"#work\" class=\"button primary swui-1\">Work</a>")
    #expect(rendered.cssString().contains("padding: 12px"))
}

@Test func protocolButtonStyleCompilesAndRendersOnButton() {
    let rendered = HTMLRenderer().renderView(
        Button("Funico")
            .buttonStyle(.myAppPrimaryButton)
    )
    let html = rendered.htmlString()
    let css = rendered.cssString()

    #expect(html == "<button class=\"swui-1\">Funico</button>")
    #expect(!html.contains("<span"))
    #expect(!html.contains("<a"))
    #expect(css.contains("padding-left: 15px"))
    #expect(css.contains("padding-right: 15px"))
    #expect(css.contains("padding-top: 5px"))
    #expect(css.contains("padding-bottom: 5px"))
    #expect(css.contains("font-weight: bold"))
    #expect(css.contains("color: #fff"))
    #expect(css.contains("background-color: var(--color-accent, #2563eb)"))
    #expect(css.contains("border-radius: 999px"))
}

@Test func protocolButtonStyleRendersOnLinkAndKeepsAnchorElement() {
    let rendered = HTMLRenderer().renderView(
        Link("Bekijk mijn werk", destination: "#work")
            .buttonStyle(.myAppPrimaryButton)
    )
    let html = rendered.htmlString()
    let css = rendered.cssString()

    #expect(html == "<a href=\"#work\" class=\"swui-1\">Bekijk mijn werk</a>")
    #expect(!html.contains("<button"))
    #expect(!html.contains("<span"))
    #expect(css.contains("padding-left: 15px"))
    #expect(css.contains("padding-right: 15px"))
    #expect(css.contains("padding-top: 5px"))
    #expect(css.contains("padding-bottom: 5px"))
    #expect(css.contains("font-weight: bold"))
    #expect(css.contains("color: #fff"))
    #expect(css.contains("background-color: var(--color-accent, #2563eb)"))
    #expect(css.contains("border-radius: 999px"))
}

@Test func tokenBasedButtonStylesStillRender() {
    let rendered = HTMLRenderer().renderView(
        HStack {
            Link("Primary", destination: "#primary")
                .buttonStyle(.primary)
            Button("Secondary")
                .buttonStyle(.secondary)
        }
    )
    let html = rendered.htmlString()
    let css = rendered.cssString()

    #expect(html.contains("<a href=\"#primary\" class=\"button primary swui-2\">Primary</a>"))
    #expect(html.contains("<button class=\"button secondary swui-3\">Secondary</button>"))
    #expect(css.contains("background-color: var(--color-accent, #2563eb)"))
    #expect(css.contains("border: 1px solid var(--color-border, #d1d5db)"))
}

@Test func stateAndBindingCompileAndCarryValues() {
    struct CounterView: View {
        @State var count = 1

        var body: some View {
            Button("Increment")
                .setState("count", to: "\(count + 1)")
        }

        var binding: Binding<Int> {
            $count
        }
    }

    let view = CounterView()
    let binding = view.binding
    #expect(binding.wrappedValue == 1)
    binding.wrappedValue = 3
    #expect(binding.wrappedValue == 3)
    #expect(HTMLRenderer().render(view).contains("data-swiftwebui-state-value=\"4\""))
}

@Test func tabBarStaticSelectionCompilesAndRendersAccessibleTabs() {
    let rendered = HTMLRenderer().renderView(
        TabBar(selection: PortfolioTab.work) {
            Tab("Werk", value: PortfolioTab.work)
            Tab("Persoonlijk", value: PortfolioTab.personal)
            Tab("Contact", value: PortfolioTab.contact)
        }
    )
    let html = rendered.htmlString()
    let css = rendered.cssString()

    #expect(html.contains("<div role=\"tablist\" class=\"swiftwebui-tab-bar swui-1\">"))
    #expect(html.contains("<button type=\"button\" role=\"tab\" aria-selected=\"true\" class=\"swiftwebui-tab swiftwebui-tab-selected swui-2\"><span>Werk</span></button>"))
    #expect(html.contains("<button type=\"button\" role=\"tab\" aria-selected=\"false\" class=\"swiftwebui-tab swui-3\"><span>Persoonlijk</span></button>"))
    #expect(html.contains("<button type=\"button\" role=\"tab\" aria-selected=\"false\" class=\"swiftwebui-tab swui-3\"><span>Contact</span></button>"))
    #expect(!html.contains("style="))
    #expect(css.contains(".swui-1"))
    #expect(css.contains("display: flex"))
    #expect(css.contains("gap: 8px"))
    #expect(css.contains(".swui-2"))
    #expect(css.contains("background-color: var(--color-accent, #2563eb)"))
    #expect(css.contains("color: #fff"))
    #expect(css.contains(".swui-3"))
    #expect(css.contains("background-color: var(--color-surface, #ffffff)"))
    #expect(css.contains("color: var(--color-secondary, #4b5563)"))
}

@Test func tabBarSupportsViewLabelsAndConditionalTabs() {
    let includeContact = true
    let rendered = HTMLRenderer().renderView(
        TabBar(selection: PortfolioTab.personal) {
            Tab(value: PortfolioTab.work) {
                Image("/briefcase.svg", alt: "Werk")
                Text("Werk")
            }
            Tab("Persoonlijk", value: PortfolioTab.personal)
            if includeContact {
                Tab("Contact", value: PortfolioTab.contact)
            }
        }
    )
    let html = rendered.htmlString()

    #expect(html.contains("<img src=\"/briefcase.svg\" alt=\"Werk\"><span>Werk</span>"))
    #expect(html.contains("<span>Persoonlijk</span>"))
    #expect(html.contains("<span>Contact</span>"))
    #expect(html.contains("aria-selected=\"true\""))
    #expect(html.contains("aria-selected=\"false\""))
}

@Test func tabBarBindingSelectionRendersCurrentSnapshotOnly() {
    struct BoundTabs: View {
        @State var selection = PortfolioTab.contact

        var body: some View {
            TabBar(selection: $selection) {
                Tab("Werk", value: PortfolioTab.work)
                Tab("Contact", value: PortfolioTab.contact)
            }
        }
    }

    let html = HTMLRenderer().render(BoundTabs())

    #expect(html.contains("<span>Contact</span></button>"))
    #expect(html.contains("aria-selected=\"true\""))
    #expect(!html.contains("data-swiftwebui-action=\"set-state\""))
}

@Test func proofOfConceptPageRendersStableHTML() {
    let rendered = HTMLRenderer().renderView(SwiftWebUIDummy())
    let html = rendered.htmlString()
    let css = rendered.cssString()
    
    #expect(html == """
    <div class="swui-1"><span class="swui-2">Maak websites met Swift.</span><div class="swui-3"><a href="#work" class="button primary swui-4">Bekijk mijn werk</a><a href="#contact" class="button secondary swui-5">Neem contact op</a><button data-swiftwebui-action="set-state" data-swiftwebui-state-key="activeTimeline" data-swiftwebui-state-value="funico" class="button secondary swui-5">Funico</button></div></div>
    """)
    #expect(!html.contains("style="))
    #expect(css.contains(".swui-1"))
    #expect(css.contains("flex-direction: column"))
    #expect(css.contains("gap: 28px"))
    #expect(css.contains("padding: 24px"))
    #expect(css.contains(".swui-2"))
    #expect(css.contains("font-size: clamp(2.5rem, 6vw, 5.5rem)"))
    #expect(css.contains("color: var(--color-primary, #111827)"))
    #expect(css.contains(".swui-3"))
    #expect(css.contains("flex-direction: row"))
    #expect(css.contains("gap: 12px"))
    #expect(css.contains(".swui-4"))
    #expect(css.contains("background-color: var(--color-accent, #2563eb)"))
    #expect(css.contains(".swui-5"))
    #expect(css.contains("border: 1px solid var(--color-border, #d1d5db)"))
    #expect(rendered.jsString().isEmpty)
}

@Test func proofOfConceptPageCanExportHTMLAndCSSStrings() {
    let rendered = HTMLRenderer().renderView(SwiftWebUIDummy())

    #expect(!rendered.htmlString(prettyPrinted: true).isEmpty)
    #expect(!rendered.cssString(prettyPrinted: true).isEmpty)
}

@Test func webDocumentRendersFullHTMLDocument() {
    let document = WebDocument(
        title: "SwiftWebUI Preview",
        renderedView: HTMLRenderer().renderView(
            Text("Hello Document")
                .foregroundStyle(.primary)
        )
    )
    let html = document.htmlString(prettyPrinted: false)

    #expect(html.hasPrefix("<!DOCTYPE html>"))
    #expect(html.contains("<html>"))
    #expect(html.contains("<head>"))
    #expect(html.contains("<body>"))
    #expect(html.contains("<meta charset=\"utf-8\">"))
    #expect(html.contains("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"))
    #expect(html.contains("<title>SwiftWebUI Preview</title>"))
    #expect(html.contains("<link rel=\"stylesheet\" href=\"styles.css\">"))
    #expect(html.contains("<span class=\"swui-1\">Hello Document</span>"))
}

@Test func webDocumentOmitsTitleWhenMissing() {
    let document = WebDocument(
        renderedView: HTMLRenderer().renderView(Text("Untitled"))
    )

    #expect(!document.htmlString(prettyPrinted: false).contains("<title>"))
}

@Test func webDocumentLinksStylesheetOnlyWhenCSSExistsAndPathIsSet() {
    let unstyledDocument = WebDocument(
        renderedView: HTMLRenderer().renderView(Text("Plain")),
        stylesheetPath: "styles.css"
    )
    let styledWithoutPath = WebDocument(
        renderedView: HTMLRenderer().renderView(
            Text("Styled")
                .foregroundStyle(.primary)
        ),
        stylesheetPath: nil
    )

    #expect(!unstyledDocument.htmlString(prettyPrinted: false).contains("<link rel=\"stylesheet\""))
    #expect(!styledWithoutPath.htmlString(prettyPrinted: false).contains("<link rel=\"stylesheet\""))
}

@Test func webDocumentLinksScriptOnlyWhenJSExistsAndPathIsSet() {
    let rendered = RenderedView(
        content: HTMLRenderer().renderView(Text("Interactive")).content,
        resources: RenderedResources(
            scripts: [
                ScriptResource(
                    id: "app",
                    scope: .global,
                    content: "console.log('ready');"
                )
            ]
        )
    )
    let document = WebDocument(
        renderedView: rendered,
        stylesheetPath: nil,
        scriptPath: "app.js"
    )
    let withoutScriptPath = WebDocument(
        renderedView: rendered,
        stylesheetPath: nil,
        scriptPath: nil
    )
    let withoutScriptContent = WebDocument(
        renderedView: HTMLRenderer().renderView(Text("Static")),
        stylesheetPath: nil,
        scriptPath: "app.js"
    )

    #expect(document.htmlString(prettyPrinted: false).contains("<script src=\"app.js\"></script>"))
    #expect(!withoutScriptPath.htmlString(prettyPrinted: false).contains("<script"))
    #expect(!withoutScriptContent.htmlString(prettyPrinted: false).contains("<script"))
}

@Test func webDocumentKeepsGeneratedCSSAvailableSeparately() {
    let rendered = HTMLRenderer().renderView(
        Text("Styled")
            .foregroundStyle(.primary)
    )
    let document = WebDocument(renderedView: rendered)

    #expect(document.htmlString(prettyPrinted: false).contains("<link rel=\"stylesheet\" href=\"styles.css\">"))
    #expect(rendered.cssString().contains("color: var(--color-primary, #111827)"))
    #expect(!document.htmlString(prettyPrinted: false).contains("color: var(--color-primary, #111827)"))
}

@Test func customHTMLNodeImplementationDoesNotRemain() throws {
    let sourceRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: "Sources/SwiftWebUI")

    let sourceFiles = try FileManager.default
        .subpathsOfDirectory(atPath: sourceRoot.path())
        .filter { $0.hasSuffix(".swift") }

    let combinedSource = try sourceFiles
        .map { try String(contentsOf: sourceRoot.appending(path: $0), encoding: .utf8) }
        .joined(separator: "\n")

    #expect(!combinedSource.contains("struct HTMLNode"))
    #expect(!combinedSource.contains("escapedHTMLText"))
    #expect(!combinedSource.contains("escapedHTMLAttribute"))
    #expect(!combinedSource.contains("DirectlyRenderable"))
}

@Test func rawCSSStyleWrappersDoNotRemainInSwiftWebUI() throws {
    let sourceRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appending(path: "Sources/SwiftWebUI")

    let sourceFiles = try FileManager.default
        .subpathsOfDirectory(atPath: sourceRoot.path())
        .filter { $0.hasSuffix(".swift") }

    let combinedSource = try sourceFiles
        .map { try String(contentsOf: sourceRoot.appending(path: $0), encoding: .utf8) }
        .joined(separator: "\n")

    #expect(!combinedSource.contains("public struct Border"))
    #expect(!combinedSource.contains("public struct Shadow"))
    #expect(!combinedSource.contains("var cssProperty: any CSSProperty {\n        SwiftCSS.Border"))
}

@Test func exportPortfolioSpikeToFiles() throws {
    let rendered = HTMLRenderer().renderView(SwiftWebUIDummy())
    let document = WebDocument(
        title: "SwiftWebUI Preview",
        renderedView: rendered,
        stylesheetPath: "styles.css"
    )
    
    let folder = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("SwiftWebUIPreview", isDirectory: true)

    try PreviewExporter.export(document, to: folder)

    let html = try String(contentsOf: folder.appendingPathComponent("index.html"), encoding: .utf8)
    let css = try String(contentsOf: folder.appendingPathComponent("styles.css"), encoding: .utf8)

    #expect(html.contains("<!DOCTYPE html>"))
    #expect(html.contains("<link rel=\"stylesheet\" href=\"styles.css\">"))
    #expect(css.contains(".swui-1"))
    
    print(folder.path)
}
