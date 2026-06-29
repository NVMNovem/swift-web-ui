import Testing
@testable import SwiftWebUI
import Foundation
import SwiftHTML

enum TimeLineNavigation: String, Sendable {
    case novem
    case funico
}

enum PortfolioTab: String, CaseIterable {
    case info
    case personal
    case contact
}

struct PortfolioPreview: View {
    @State private var selectedTab = PortfolioTab.info
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Maak websites met Swift.")
                .font(.largeTitle)
                .foregroundStyle(.primary)
            
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

private func generatedClassNames(in string: String) -> [String] {
    let pattern = #"swui-[0-9a-f]{16}"#
    let regex = try! NSRegularExpression(pattern: pattern)
    let range = NSRange(string.startIndex..<string.endIndex, in: string)

    return regex.matches(in: string, range: range).compactMap { match in
        guard let range = Range(match.range, in: string) else {
            return nil
        }

        return String(string[range])
    }
}

private func uniqueGeneratedClassNames(in string: String) -> [String] {
    var seen: Set<String> = []
    var names: [String] = []

    for name in generatedClassNames(in: string) where seen.insert(name).inserted {
        names.append(name)
    }

    return names
}

private func singleGeneratedClass(in rendered: RenderedView) -> String {
    let names = uniqueGeneratedClassNames(in: rendered.htmlString())
    #expect(names.count == 1)
    return names.first ?? ""
}

private func cssRuleCount(in css: String, for className: String) -> Int {
    css.components(separatedBy: ".\(className) {").count - 1
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

@Test func rendersTextSemanticRoleH1() {
    let renderer = HTMLRenderer()
    let nodes = renderer.renderNodes(Text("Title").semanticRole(.h1))
    let html = nodes.map { $0.render(prettyPrinted: false) }.joined()

    #expect(nodes.first is H1)
    #expect(html == "<h1>Title</h1>")
}

@Test func rendersTextSemanticRoleParagraph() {
    let html = HTMLRenderer().render(
        Text("Intro").semanticRole(.p)
    )

    #expect(html == "<p>Intro</p>")
}

@Test func semanticTextRoleKeepsClassIDAndAttributeModifiers() {
    let html = HTMLRenderer().render(
        Text("Title")
            .semanticRole(.h1)
            .attribute("data-kind", "hero")
            .class("hero-title")
            .id("title")
    )

    #expect(html == "<h1 data-kind=\"hero\" class=\"hero-title\" id=\"title\">Title</h1>")
}

@Test func semanticTextRoleKeepsStylingModifiers() {
    let rendered = HTMLRenderer().renderView(
        Text("Styled")
            .semanticRole(.p)
            .font(.largeTitle)
            .foregroundStyle(.primary)
    )
    let html = rendered.htmlString()
    let css = rendered.cssString()
    let className = singleGeneratedClass(in: rendered)

    #expect(html == "<p class=\"\(className)\">Styled</p>")
    #expect(css.contains(".\(className)"))
    #expect(css.contains("font-size: 34px"))
    #expect(css.contains("font-weight: 400"))
    #expect(css.contains("color: var(--color-primary, #111827)"))
}

@Test func systemFontSizeEmitsFontSizeCSS() {
    let rendered = HTMLRenderer().renderView(
        Text("Sized")
            .font(.system(size: 19))
    )

    #expect(rendered.cssString().contains("font-size: 19px"))
}

@Test func systemFontBlackWeightEmitsNumericCSSWeight() {
    let rendered = HTMLRenderer().renderView(
        Text("Heavy")
            .font(.system(size: 19, weight: .black))
    )
    let css = rendered.cssString()

    #expect(css.contains("font-size: 19px"))
    #expect(css.contains("font-weight: 900"))
}

@Test func systemFontCustomWeightEmitsNumericCSSWeight() {
    let rendered = HTMLRenderer().renderView(
        Text("Heavy")
            .font(.system(size: 19, weight: .weight(800)))
    )

    #expect(rendered.cssString().contains("font-weight: 800"))
}

@Test func systemFontDesignEmitsFontFamilyCSS() {
    let css = HTMLRenderer().renderView(
        Text("Code")
            .font(.system(size: 19, design: .monospaced))
    ).cssString()

    #expect(css.contains("font-family: ui-monospace"))
}

@Test func headlineFontEmitsExpectedSizeAndWeight() {
    let css = HTMLRenderer().renderView(
        Text("Headline")
            .font(.headline)
    ).cssString()

    #expect(css.contains("font-size: 17px"))
    #expect(css.contains("font-weight: 600"))
}

@Test func caption2FontEmitsExpectedSize() {
    let css = HTMLRenderer().renderView(
        Text("Caption")
            .font(.caption2)
    ).cssString()

    #expect(css.contains("font-size: 11px"))
}

@Test func fontWorksWithSemanticHeadingWithoutChangingSemanticOutput() {
    let rendered = HTMLRenderer().renderView(
        Text("Title")
            .semanticRole(.h1)
            .font(.largeTitle)
    )
    let className = singleGeneratedClass(in: rendered)

    #expect(rendered.htmlString() == "<h1 class=\"\(className)\">Title</h1>")
    #expect(rendered.cssString().contains("font-size: 34px"))
}

@Test func semanticHeadingAloneDoesNotEmitFontCSS() {
    let rendered = HTMLRenderer().renderView(
        Text("Title")
            .semanticRole(.h1)
    )

    #expect(rendered.htmlString() == "<h1>Title</h1>")
    #expect(!rendered.cssString().contains("font-size"))
    #expect(!rendered.cssString().contains("font-weight"))
}

@Test func fontComposesWithClassIDAndAttributeModifiers() {
    let rendered = HTMLRenderer().renderView(
        Text("Styled")
            .font(.system(size: 19))
            .class("custom")
            .id("styled")
            .attribute("data-kind", "sample")
    )
    let className = singleGeneratedClass(in: rendered)

    #expect(rendered.htmlString() == "<span data-kind=\"sample\" class=\"custom \(className)\" id=\"styled\">Styled</span>")
    #expect(rendered.cssString().contains("font-size: 19px"))
}

@Test func semanticTextRolesRenderInsideVStackGroupAndSection() {
    let rendered = HTMLRenderer().renderView(
        VStack(spacing: 12) {
            Group {
                Text("Title").semanticRole(.h1)
                Text("Intro").semanticRole(.p)
            }
            Section {
                Text("Details").semanticRole(.h2)
            }
        }
    )
    let html = rendered.htmlString()

    #expect(html.contains("<h1>Title</h1><p>Intro</p>"))
    #expect(html.contains("<section><h2>Details</h2></section>"))
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
    let classes = uniqueGeneratedClassNames(in: html)
    
    #expect(classes.count == 2)
    #expect(html.contains("<div class=\"\(classes.first ?? "")\">"))
    #expect(html.contains("<span>Top</span>"))
    #expect(html.contains("<div class=\"\(classes.dropFirst().first ?? "")\">"))
    #expect(html.contains("<span>Left</span><span>Right</span>"))
    #expect(!html.contains("style="))
    #expect(css.contains(".\(classes.first ?? "")"))
    #expect(css.contains("flex-direction: column"))
    #expect(css.contains("gap: 20px"))
    #expect(css.contains(".\(classes.dropFirst().first ?? "")"))
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
            .font(.largeTitle)
            .cornerRadius(12)
            .border("1px solid currentColor")
            .shadow("0 12px 40px rgba(0, 0, 0, 0.12)")
            .gap(10)
    )
    let html = rendered.htmlString()
    let css = rendered.cssString()
    let className = singleGeneratedClass(in: rendered)
    
    #expect(html == "<span class=\"\(className)\">Styled</span>")
    #expect(!html.contains("style="))
    #expect(css.contains("padding-left: 16px"))
    #expect(css.contains("padding-right: 16px"))
    #expect(css.contains("width: 320px"))
    #expect(css.contains("max-width: 100%"))
    #expect(css.contains("background-color: #fff"))
    #expect(css.contains("color: var(--color-primary, #111827)"))
    #expect(css.contains("font-size: 34px"))
    #expect(css.contains("font-weight: 400"))
    #expect(css.contains("border-radius: 12px"))
    #expect(css.contains("border: 1px solid currentColor"))
    #expect(css.contains("box-shadow: 0 12px 40px rgba(0, 0, 0, 0.12)"))
    #expect(css.contains("gap: 10px"))
}

@Test func sizingModifiersRenderOnNormalViews() {
    let rendered = HTMLRenderer().renderView(
        Text("Sized")
            .width(.percent(100))
            .minWidth(.px(120))
            .maxWidth(.px(380))
            .height(.px(240))
            .minHeight(.px(80))
            .maxHeight(.px(420))
    )
    let html = rendered.htmlString()
    let css = rendered.cssString()
    let className = singleGeneratedClass(in: rendered)

    #expect(html == "<span class=\"\(className)\">Sized</span>")
    #expect(!html.contains("style="))
    #expect(css.contains("width: 100%"))
    #expect(css.contains("min-width: 120px"))
    #expect(css.contains("max-width: 380px"))
    #expect(css.contains("height: 240px"))
    #expect(css.contains("min-height: 80px"))
    #expect(css.contains("max-height: 420px"))
}

@Test func sizingModifiersRenderOnImage() {
    let rendered = HTMLRenderer().renderView(
        Image("assets/profile1.jpeg", alt: "Damian Van de Kauter")
            .width(.percent(100))
            .maxWidth(.px(380))
    )
    let html = rendered.htmlString()
    let css = rendered.cssString()
    let className = singleGeneratedClass(in: rendered)

    #expect(html == "<img src=\"assets/profile1.jpeg\" alt=\"Damian Van de Kauter\" class=\"\(className)\">")
    #expect(css.contains("width: 100%"))
    #expect(css.contains("max-width: 380px"))
}

@Test func gridRendersWrapperWithDisplayGrid() {
    let rendered = HTMLRenderer().renderView(
        Grid {
            Text("A")
            Text("B")
        }
    )
    let html = rendered.htmlString()
    let css = rendered.cssString()
    let className = singleGeneratedClass(in: rendered)

    #expect(html == "<div class=\"\(className)\"><span>A</span><span>B</span></div>")
    #expect(css.contains("display: grid"))
}

@Test func gridSpacingRendersGap() {
    let rendered = HTMLRenderer().renderView(
        Grid(spacing: .px(24)) {
            Text("A")
            Text("B")
        }
    )
    let css = rendered.cssString()

    #expect(css.contains("display: grid"))
    #expect(css.contains("gap: 24px"))
}

@Test func gridPreservesUserClassWithGeneratedClass() {
    let rendered = HTMLRenderer().renderView(
        Grid(spacing: .px(24)) {
            Text("A")
            Text("B")
        }
        .class("about-cards")
    )
    let className = singleGeneratedClass(in: rendered)

    #expect(rendered.htmlString() == "<div class=\"about-cards \(className)\"><span>A</span><span>B</span></div>")
    #expect(rendered.cssString().contains("display: grid"))
}

@Test func gridWorksInsideSectionAndGroup() {
    let rendered = HTMLRenderer().renderView(
        Section {
            Group {
                Grid {
                    Text("A")
                    Text("B")
                }
            }
        }
    )
    let html = rendered.htmlString()
    let css = rendered.cssString()
    let className = singleGeneratedClass(in: rendered)

    #expect(html == "<section><div class=\"\(className)\"><span>A</span><span>B</span></div></section>")
    #expect(css.contains("display: grid"))
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

@Test func rendersGenericDataAttribute() {
    let html = HTMLRenderer().render(
        Text("Item")
            .attribute("data-scroll-target", "work")
    )
    
    #expect(html == "<span data-scroll-target=\"work\">Item</span>")
}

@Test func rendersGenericAriaAttribute() {
    let html = HTMLRenderer().render(
        Div {
            Text("Details")
        }
        .attribute("aria-label", "Expertise")
    )
    
    #expect(html == "<div aria-label=\"Expertise\"><span>Details</span></div>")
}

@Test func genericAttributesCombineWithClassAndIDModifiers() {
    let html = HTMLRenderer().render(
        Div {
            Text("Panel")
        }
        .attribute("data-kind", "summary")
        .class("card")
        .id("panel")
    )
    
    #expect(html == "<div data-kind=\"summary\" class=\"card\" id=\"panel\"><span>Panel</span></div>")
}

@Test func groupRendersWithoutWrapperWhenUnmodified() {
    let html = HTMLRenderer().render(
        Group {
            Text("A")
            Text("B")
        }
    )

    #expect(html == "<span>A</span><span>B</span>")
}

@Test func groupClassModifierRendersImplicitDivWrapper() {
    let html = HTMLRenderer().render(
        Group {
            Text("A")
            Text("B")
        }
        .class("test")
    )

    #expect(html == "<div class=\"test\"><span>A</span><span>B</span></div>")
}

@Test func groupIDModifierRendersImplicitDivWrapper() {
    let html = HTMLRenderer().render(
        Group {
            Text("A")
            Text("B")
        }
        .id("test")
    )

    #expect(html == "<div id=\"test\"><span>A</span><span>B</span></div>")
}

@Test func groupAttributeModifierRendersImplicitDivWrapper() {
    let html = HTMLRenderer().render(
        Group {
            Text("A")
            Text("B")
        }
        .attribute("data-test", "true")
    )

    #expect(html == "<div data-test=\"true\"><span>A</span><span>B</span></div>")
}

@Test func nestedGroupsRenderWithoutExtraWrappers() {
    let html = HTMLRenderer().render(
        Group {
            Group {
                Text("A")
            }
        }
    )

    #expect(html == "<span>A</span>")
}

@Test func groupInsideStacksRendersAsTransparentStackContent() {
    let vstack = HTMLRenderer().renderView(
        VStack {
            Group {
                Text("A")
                Text("B")
            }
        }
    )
    let hstack = HTMLRenderer().renderView(
        HStack {
            Group {
                Text("A")
                Text("B")
            }
        }
    )
    let vstackClass = singleGeneratedClass(in: vstack)
    let hstackClass = singleGeneratedClass(in: hstack)

    #expect(vstack.htmlString() == "<div class=\"\(vstackClass)\"><span>A</span><span>B</span></div>")
    #expect(vstack.cssString().contains("flex-direction: column"))
    #expect(hstack.htmlString() == "<div class=\"\(hstackClass)\"><span>A</span><span>B</span></div>")
    #expect(hstack.cssString().contains("flex-direction: row"))
    #expect(vstackClass != hstackClass)
}

@Test func stacksInsideGroupRenderNormally() {
    let rendered = HTMLRenderer().renderView(
        Group {
            VStack {
                Text("A")
            }
            HStack {
                Text("B")
            }
        }
    )
    let html = rendered.htmlString()
    let css = rendered.cssString()
    let classes = uniqueGeneratedClassNames(in: html)

    #expect(classes.count == 2)
    #expect(html == "<div class=\"\(classes.first ?? "")\"><span>A</span></div><div class=\"\(classes.dropFirst().first ?? "")\"><span>B</span></div>")
    #expect(css.contains("flex-direction: column"))
    #expect(css.contains("flex-direction: row"))
}

@Test func linkAttributePreservesHref() {
    let html = HTMLRenderer().render(
        Link("Open", destination: "#target")
            .attribute("data-scroll-target", "target")
    )
    
    #expect(html == "<a href=\"#target\" data-scroll-target=\"target\">Open</a>")
}

@Test func nestedSectionDivAndHStackRenderValidOutputWithAttributes() {
    let rendered = HTMLRenderer().renderView(
        Section {
            Div {
                HStack {
                    Text("One")
                    Text("Two")
                }
                .class("row")
            }
            .attribute("data-kind", "content")
        }
        .attribute("aria-label", "Group")
    )
    let html = rendered.htmlString()
    let css = rendered.cssString()
    let className = singleGeneratedClass(in: rendered)
    
    #expect(html.contains("<section aria-label=\"Group\">"))
    #expect(html.contains("<div data-kind=\"content\">"))
    #expect(html.contains("<div class=\"row \(className)\">"))
    #expect(html.contains("<span>One</span><span>Two</span>"))
    #expect(html.contains("</div></div></section>"))
    #expect(css.contains("flex-direction: row"))
}

@Test func renderViewReturnsContentAndResourcesSeparately() {
    let rendered = HTMLRenderer().renderView(
        Text("Hello")
            .foregroundStyle(.primary)
    )
    let className = singleGeneratedClass(in: rendered)
    
    #expect(rendered.htmlString() == "<span class=\"\(className)\">Hello</span>")
    #expect(rendered.cssString().contains(".\(className)"))
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
    let rendered = HTMLRenderer().renderView(
        Text("Hello")
            .foregroundStyle(.primary)
    )
    let className = singleGeneratedClass(in: rendered)
    
    #expect(html == "<span class=\"\(className)\">Hello</span>")
    #expect(!html.contains("color: var(--color-primary, #111827)"))
}

@Test func preservesUserClassesWhenAddingGeneratedClass() {
    let rendered = HTMLRenderer().renderView(
        Link("Work", destination: "#work")
            .class("button primary")
            .padding(12)
    )
    let className = singleGeneratedClass(in: rendered)
    
    #expect(rendered.htmlString() == "<a href=\"#work\" class=\"button primary \(className)\">Work</a>")
    #expect(rendered.cssString().contains("padding: 12px"))
}

@Test func identicalModifierChainsUseSameGeneratedClassInOneRender() {
    let rendered = HTMLRenderer().renderView(
        Group {
            Text("Title")
                .font(.system(size: 19, weight: .heavy))
                .padding(.bottom, .px(5))
            Text("Subtitle")
                .font(.system(size: 19, weight: .heavy))
                .padding(.bottom, .px(5))
        }
    )
    let htmlClassNames = generatedClassNames(in: rendered.htmlString())
    let uniqueClassNames = uniqueGeneratedClassNames(in: rendered.htmlString())
    let className = uniqueClassNames.first ?? ""
    
    #expect(htmlClassNames.count == 2)
    #expect(uniqueClassNames.count == 1)
    #expect(rendered.htmlString().contains("<span class=\"\(className)\">Title</span><span class=\"\(className)\">Subtitle</span>"))
    #expect(cssRuleCount(in: rendered.cssString(), for: className) == 1)
    #expect(rendered.cssString().contains("font-size: 19px"))
    #expect(rendered.cssString().contains("font-weight: 800"))
    #expect(rendered.cssString().contains("padding-bottom: 5px"))
}

@Test func differentModifierChainsUseDifferentGeneratedClassesInOneRender() {
    let rendered = HTMLRenderer().renderView(
        Group {
            Text("Title")
                .font(.system(size: 19, weight: .heavy))
            Text("Subtitle")
                .font(.system(size: 20, weight: .heavy))
        }
    )
    let classNames = uniqueGeneratedClassNames(in: rendered.htmlString())
    
    #expect(classNames.count == 2)
    #expect(classNames.first != classNames.dropFirst().first)
    #expect(rendered.cssString().contains("font-size: 19px"))
    #expect(rendered.cssString().contains("font-size: 20px"))
}

@Test func separateRendersWithIdenticalDeclarationsUseSameGeneratedClass() {
    let first = HTMLRenderer().renderView(
        Text("Title")
            .font(.system(size: 19, weight: .heavy))
            .padding(.bottom, .px(5))
    )
    let second = HTMLRenderer().renderView(
        Text("Other")
            .font(.system(size: 19, weight: .heavy))
            .padding(.bottom, .px(5))
    )
    
    #expect(singleGeneratedClass(in: first) == singleGeneratedClass(in: second))
    #expect(first.cssString() == second.cssString())
}

@Test func separateRendersWithDifferentDeclarationsDoNotCollide() {
    let first = HTMLRenderer().renderView(
        Text("Title")
            .font(.system(size: 19, weight: .heavy))
    )
    let second = HTMLRenderer().renderView(
        Text("Title")
            .font(.system(size: 20, weight: .heavy))
    )
    
    #expect(singleGeneratedClass(in: first) != singleGeneratedClass(in: second))
}

@Test func userClassesArePreservedAlongsideContentBasedGeneratedClasses() {
    let rendered = HTMLRenderer().renderView(
        Text("42")
            .class("metric-card")
            .font(.system(size: 19, weight: .heavy))
            .padding(.bottom, .px(5))
    )
    let className = singleGeneratedClass(in: rendered)
    
    #expect(rendered.htmlString() == "<span class=\"metric-card \(className)\">42</span>")
    #expect(rendered.cssString().contains(".\(className)"))
}

@Test func protocolButtonStyleCompilesAndRendersOnButton() {
    let rendered = HTMLRenderer().renderView(
        Button("Funico")
            .buttonStyle(.myAppPrimaryButton)
    )
    let html = rendered.htmlString()
    let css = rendered.cssString()
    let className = singleGeneratedClass(in: rendered)
    
    #expect(html == "<button class=\"\(className)\">Funico</button>")
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
    let className = singleGeneratedClass(in: rendered)
    
    #expect(html == "<a href=\"#work\" class=\"\(className)\">Bekijk mijn werk</a>")
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
    let classes = uniqueGeneratedClassNames(in: html)
    
    #expect(classes.count == 3)
    #expect(html.contains("<a href=\"#primary\" class=\"button primary \(classes.dropFirst().first ?? "")\">Primary</a>"))
    #expect(html.contains("<button class=\"button secondary \(classes.dropFirst(2).first ?? "")\">Secondary</button>"))
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
    #expect(binding.clientState?.key.isEmpty == false)
    #expect(binding.clientState?.initialValue == "1")
    #expect(HTMLRenderer().render(view).contains("data-swiftwebui-state-value=\"4\""))
}

@Test func stateProjectedValueExposesClientStateMetadata() {
    struct BoundTabs: View {
        @State var selection = PortfolioTab.contact
        
        var body: some View {
            EmptyView()
        }
        
        var binding: Binding<PortfolioTab> {
            $selection
        }
    }
    
    let metadata = BoundTabs().binding.clientState
    
    #expect(metadata?.key.isEmpty == false)
    #expect(metadata?.initialValue == "contact")
}

@Test func tabBarStaticSelectionCompilesAndRendersAccessibleTabs() {
    let rendered = HTMLRenderer().renderView(
        TabBar(selection: PortfolioTab.info) {
            Tab("Info", value: PortfolioTab.info)
            Tab("Persoonlijk", value: PortfolioTab.personal)
            Tab("Contact", value: PortfolioTab.contact)
        }
    )
    let html = rendered.htmlString()
    let css = rendered.cssString()
    let classes = uniqueGeneratedClassNames(in: html)
    
    #expect(classes.count == 3)
    #expect(html.contains("<div role=\"tablist\" class=\"swiftwebui-tab-bar \(classes.first ?? "")\">"))
    #expect(html.contains("<button type=\"button\" role=\"tab\" aria-selected=\"true\" class=\"swiftwebui-tab swiftwebui-tab-selected \(classes.dropFirst().first ?? "")\"><span>Info</span></button>"))
    #expect(html.contains("<button type=\"button\" role=\"tab\" aria-selected=\"false\" class=\"swiftwebui-tab \(classes.dropFirst(2).first ?? "")\"><span>Persoonlijk</span></button>"))
    #expect(html.contains("<button type=\"button\" role=\"tab\" aria-selected=\"false\" class=\"swiftwebui-tab \(classes.dropFirst(2).first ?? "")\"><span>Contact</span></button>"))
    #expect(!html.contains("style="))
    #expect(css.contains(".\(classes.first ?? "")"))
    #expect(css.contains("display: flex"))
    #expect(css.contains("gap: 8px"))
    #expect(css.contains(".\(classes.dropFirst().first ?? "")"))
    #expect(css.contains("background-color: var(--color-accent, #2563eb)"))
    #expect(css.contains("color: #fff"))
    #expect(css.contains(".\(classes.dropFirst(2).first ?? "")"))
    #expect(css.contains("background-color: var(--color-surface, #ffffff)"))
    #expect(css.contains("color: var(--color-secondary, #4b5563)"))
}

@Test func tabBarSupportsViewLabelsAndConditionalTabs() {
    let includeContact = true
    let rendered = HTMLRenderer().renderView(
        TabBar(selection: PortfolioTab.personal) {
            Tab(value: PortfolioTab.info) {
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

@Test func tabBarBindingSelectionRendersClientStateAttributesAndRuntime() {
    struct BoundTabs: View {
        @State var selection = PortfolioTab.contact
        
        var body: some View {
            TabBar(selection: $selection) {
                Tab("Info", value: PortfolioTab.info)
                Tab("Contact", value: PortfolioTab.contact)
            }
        }
    }
    
    let rendered = HTMLRenderer().renderView(BoundTabs())
    let html = rendered.htmlString()
    let js = rendered.jsString()
    
    #expect(html.contains("<span>Contact</span></button>"))
    #expect(html.contains("aria-selected=\"true\""))
    #expect(html.contains("role=\"tablist\""))
    #expect(html.contains("data-swiftwebui-state-key=\"state-"))
    #expect(html.contains("data-swiftwebui-state-initial-value=\"contact\""))
    #expect(html.contains("data-swiftwebui-action=\"set-state\""))
    #expect(html.contains("data-swiftwebui-state-value=\"info\""))
    #expect(html.contains("data-swiftwebui-state-value=\"contact\""))
    #expect(html.contains("data-swiftwebui-selected=\"true\""))
    #expect(!js.isEmpty)
    #expect(js.contains("document.addEventListener(\"click\""))
    #expect(js.contains("data-swiftwebui-action"))
    #expect(js.contains("set-state"))
    #expect(js.contains("aria-selected"))
    #expect(js.contains("dataset.swiftwebuiSelected"))
    #expect(js.contains("swiftwebui-tab-selected"))
    #expect(js.contains("data-swiftwebui-state-panel-key"))
}

@Test func setBindingToValueRendersStateMutationAttributes() {
    struct ContactButton: View {
        @State var selection = PortfolioTab.info
        
        var body: some View {
            Button("Show Contact")
                .set($selection, to: .contact)
        }
    }
    
    let rendered = HTMLRenderer().renderView(ContactButton())
    let html = rendered.htmlString()
    
    #expect(html.contains("<button"))
    #expect(html.contains("data-swiftwebui-action=\"set-state\""))
    #expect(html.contains("data-swiftwebui-state-key=\"state-"))
    #expect(html.contains("data-swiftwebui-state-value=\"contact\""))
    #expect(!html.contains("closure-placeholder"))
    
    let js = rendered.jsString()
    #expect(js.contains("document.addEventListener(\"click\""))
    #expect(js.contains("set-state"))
    #expect(js.contains("data-swiftwebui-action"))
    #expect(js.contains("dataset.swiftwebuiStateKey"))
    #expect(js.contains("dataset.swiftwebuiStateValue"))
}


@Test func clientStateRuntimeIsRegisteredOnlyOnceForMultipleStateControls() {
    struct MultipleControls: View {
        @State var selection = PortfolioTab.info
        
        var body: some View {
            VStack {
                TabBar(selection: $selection) {
                    Tab("Info", value: PortfolioTab.info)
                    Tab("Contact", value: PortfolioTab.contact)
                }
                
                Button("Show Info")
                    .set($selection, to: .info)
                
                Button("Show Contact")
                    .set($selection, to: .contact)
            }
        }
    }
    
    let rendered = HTMLRenderer().renderView(MultipleControls())
    let js = rendered.jsString()
    
    #expect(!js.isEmpty)
    #expect(rendered.resources.scripts.count == 1)
    #expect(js.components(separatedBy: "document.addEventListener(\"click\"").count == 2)
}


@Test func clientStateRuntimeUpdatesTabsAndPanelsByMatchingStateKeyAndValue() {
    struct BoundTabs: View {
        @State var selection = PortfolioTab.info
        
        var body: some View {
            TabBar(selection: $selection) {
                Tab("Info", value: PortfolioTab.info)
                Tab("Contact", value: PortfolioTab.contact)
            }
        }
    }
    
    let rendered = HTMLRenderer().renderView(BoundTabs())
    let js = rendered.jsString()
    
    #expect(js.contains("querySelectorAll"))
    #expect(js.contains("role=\"tab\""))
    #expect(js.contains("aria-selected"))
    #expect(js.contains("dataset.swiftwebuiSelected"))
    #expect(js.contains("classList.toggle"))
    #expect(js.contains("swiftwebui-tab-selected"))
    #expect(js.contains("data-swiftwebui-state-panel-key"))
    #expect(js.contains("hidden"))
}


@Test func clientStateRuntimeIsNotEmittedForStaticTabBarWithoutActions() {
    let rendered = HTMLRenderer().renderView(
        TabBar(selection: PortfolioTab.info) {
            Tab("Info", value: PortfolioTab.info)
            Tab("Contact", value: PortfolioTab.contact)
        }
    )
    
    #expect(rendered.jsString().isEmpty)
    #expect(rendered.resources.scripts.isEmpty)
}

@Test func proofOfConceptPageRendersStableHTML() {
    let rendered = HTMLRenderer().renderView(PortfolioPreview())
    let html = rendered.htmlString()
    let css = rendered.cssString()
    let classes = uniqueGeneratedClassNames(in: html)
    
    #expect(classes.count >= 5)
    #expect(html.contains("<div class=\"\(classes.first ?? "")\">"))
    #expect(html.contains("<span class=\"\(classes.dropFirst().first ?? "")\">Maak websites met Swift.</span>"))
    #expect(html.contains("role=\"tablist\""))
    #expect(html.contains("data-swiftwebui-state-key=\"state-"))
    #expect(html.contains("data-swiftwebui-state-initial-value=\"info\""))
    #expect(html.contains("data-swiftwebui-action=\"set-state\""))
    #expect(html.contains("data-swiftwebui-state-value=\"contact\""))
    #expect(html.contains("<button data-swiftwebui-action=\"set-state\""))
    #expect(html.contains("Toon contact</button>"))
    #expect(!html.contains("style="))
    #expect(css.contains(".\(classes.first ?? "")"))
    #expect(css.contains("flex-direction: column"))
    #expect(css.contains("padding: 24px"))
    #expect(css.contains(".\(classes.dropFirst().first ?? "")"))
    #expect(css.contains("font-size: 34px"))
    #expect(css.contains("font-weight: 400"))
    #expect(css.contains("color: var(--color-primary, #111827)"))
    #expect(css.contains(".\(classes.dropFirst(2).first ?? "")"))
    #expect(css.contains("flex-direction: row"))
    #expect(css.contains(".\(classes.dropFirst(3).first ?? "")"))
    #expect(css.contains("background-color: var(--color-accent, #2563eb)"))
    #expect(css.contains(".\(classes.dropFirst(4).first ?? "")"))
    #expect(css.contains("border: 1px solid var(--color-border, #d1d5db)"))
    #expect(!rendered.jsString().isEmpty)
}

@Test func proofOfConceptPageCanExportHTMLAndCSSStrings() {
    let rendered = HTMLRenderer().renderView(PortfolioPreview())
    
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
    let className = singleGeneratedClass(in: document.renderedView)
    
    #expect(html.hasPrefix("<!DOCTYPE html>"))
    #expect(html.contains("<html>"))
    #expect(html.contains("<head>"))
    #expect(html.contains("<body>"))
    #expect(html.contains("<meta charset=\"utf-8\">"))
    #expect(html.contains("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"))
    #expect(html.contains("<title>SwiftWebUI Preview</title>"))
    #expect(html.contains("<link rel=\"stylesheet\" href=\"styles.css\">"))
    #expect(html.contains("<span class=\"\(className)\">Hello Document</span>"))
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

@Test func webDocumentIncludesClientStateScriptWhenPathIsProvided() {
    struct BoundTabs: View {
        @State var selection = PortfolioTab.info
        
        var body: some View {
            TabBar(selection: $selection) {
                Tab("Info", value: PortfolioTab.info)
                Tab("Contact", value: PortfolioTab.contact)
            }
        }
    }
    
    let document = WebDocument(
        renderedView: HTMLRenderer().renderView(BoundTabs()),
        stylesheetPath: nil,
        scriptPath: "app.js"
    )
    
    #expect(document.htmlString(prettyPrinted: false).contains("<script src=\"app.js\"></script>"))
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
    let rendered = HTMLRenderer().renderView(PortfolioPreview())
    let document = WebDocument(
        title: "SwiftWebUI Preview",
        renderedView: rendered,
        stylesheetPath: "styles.css",
        scriptPath: "app.js"
    )
    
    let folder = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("SwiftWebUIPreview", isDirectory: true)
    
    try PreviewExporter.export(document, to: folder)
    
    let html = try String(contentsOf: folder.appendingPathComponent("index.html"), encoding: .utf8)
    let css = try String(contentsOf: folder.appendingPathComponent("styles.css"), encoding: .utf8)
    let js = try String(contentsOf: folder.appendingPathComponent("app.js"), encoding: .utf8)
    
    #expect(html.contains("<!DOCTYPE html>"))
    #expect(html.contains("<link rel=\"stylesheet\" href=\"styles.css\">"))
    #expect(html.contains("<script src=\"app.js\"></script>"))
    #expect(!uniqueGeneratedClassNames(in: css).isEmpty)
    #expect(js.contains("document.addEventListener(\"click\""))
    
    print(folder.path)
}

@Test func previewExporterWritesAppJSWhenClientStateExists() throws {
    struct BoundTabs: View {
        @State var selection = PortfolioTab.info
        
        var body: some View {
            VStack {
                TabBar(selection: $selection) {
                    Tab("Info", value: PortfolioTab.info)
                    Tab("Contact", value: PortfolioTab.contact)
                }
                Button("Show Contact")
                    .set($selection, to: .contact)
            }
        }
    }
    
    let rendered = HTMLRenderer().renderView(BoundTabs())
    let document = WebDocument(
        renderedView: rendered,
        stylesheetPath: "styles.css",
        scriptPath: "app.js"
    )
    let folder = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("SwiftWebUIPreviewWithState", isDirectory: true)
    
    try PreviewExporter.export(document, to: folder)
    
    let html = try String(contentsOf: folder.appendingPathComponent("index.html"), encoding: .utf8)
    let js = try String(contentsOf: folder.appendingPathComponent("app.js"), encoding: .utf8)
    
    #expect(html.contains("<script src=\"app.js\"></script>"))
    #expect(js.contains("document.addEventListener(\"click\""))
    #expect(js.contains("set-state"))
    #expect(js.contains("aria-selected"))
    #expect(js.contains("swiftwebui-tab-selected"))
}
