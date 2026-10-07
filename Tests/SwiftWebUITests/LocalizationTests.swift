//
//  LocalizationTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 07/10/2026.
//

import Foundation
import Testing
@testable import SwiftWebUI
import SwiftWebUIStatic

// MARK: - Fixtures

/// Built in code: the tests cover how views use a catalog, not how one is generated.
private let catalog = LocalizationCatalog(sourceLanguage: "en", entries: [
    "cart.title": .init(localizations: [
        "en": .init(variation: .string("Cart")),
        "nl": .init(variation: .string("Winkelwagen")),
        "fr": .init(variation: .string("Panier")),
    ]),
    "%lld items": .init(localizations: [
        "en": .init(variation: .plural(.cardinal, [.one: .string("%lld item"), .other: .string("%lld items")])),
        "pl": .init(variation: .plural(.cardinal, [
            .one: .string("%lld element"), .few: .string("%lld elementy"),
            .many: .string("%lld elementów"), .other: .string("%lld elementu"),
        ])),
    ]),
    "Hello, %@!": .init(localizations: ["nl": .init(variation: .string("Hallo, %@!"))]),
    "Order": .init(localizations: ["nl": .init(variation: .string("Bestellen"))]),
    "Terms": .init(localizations: ["nl": .init(variation: .string("Voorwaarden"))]),
])

private func html<V: View>(_ view: V) -> String {
    HTMLRenderer().renderView(view).htmlString()
}

/// A composed view, so that localization has to reach through a `body`.
private struct CartSummary: View {
    let count: Int

    var body: some View {
        VStack {
            Text("cart.title")
            Text("\(count) items")
        }
    }
}

// MARK: - Tests

@Suite struct LocalizationTests {

    @Test func aLiteralWithoutACatalogRendersAsWritten() {
        #expect(html(Text("Build browser UI in Swift")).contains(">Build browser UI in Swift<"))
        #expect(html(Text("Progress: 100%")).contains(">Progress: 100%<"))
        let count = 3
        let name = "Ada"
        #expect(html(Text("\(name) has \(count) items (\(50)%)")).contains(">Ada has 3 items (50%)<"))
    }

    @Test func aLiteralIsLookedUpInThePlacedCatalog() {
        #expect(html(Text("cart.title").localizationCatalog(catalog)).contains(">Cart<"))
        #expect(html(Text("cart.title").localizationCatalog(catalog).locale("nl")).contains(">Winkelwagen<"))
        // Modifier order does not matter: both are in effect when the text is lowered.
        #expect(html(Text("cart.title").locale("nl").localizationCatalog(catalog)).contains(">Winkelwagen<"))
    }

    @Test func localeFallsBackByTruncationThenToTheSourceLanguage() {
        #expect(html(Text("cart.title").localizationCatalog(catalog).locale("nl-BE")).contains(">Winkelwagen<"))
        #expect(html(Text("cart.title").localizationCatalog(catalog).locale("de")).contains(">Cart<"))
    }

    @Test func aMissingKeyOrLocaleShowsTheDefaultValue() {
        #expect(html(Text("Not in the catalog").localizationCatalog(catalog).locale("nl")).contains(">Not in the catalog<"))
        // "Hello, %@!" has no English entry: the literal is formatted instead.
        let name = "Ada"
        #expect(html(Text("Hello, \(name)!").localizationCatalog(catalog)).contains(">Hello, Ada!<"))
        #expect(html(Text("Hello, \(name)!").localizationCatalog(catalog).locale("nl")).contains(">Hallo, Ada!<"))
    }

    @Test(arguments: [(1, "1 element"), (3, "3 elementy"), (5, "5 elementów"), (22, "22 elementy")])
    func interpolationSelectsPluralCategories(count: Int, expected: String) {
        #expect(html(Text("\(count) items").localizationCatalog(catalog).locale("pl")).contains(">\(expected)<"))
    }

    @Test func aStringValueIsNeverLocalized() {
        let key = "cart.title"
        #expect(html(Text(key).localizationCatalog(catalog).locale("nl")).contains(">cart.title<"))
        #expect(html(Text(key.dropFirst(5)).localizationCatalog(catalog)).contains(">title<"))
        #expect(html(Text(verbatim: "cart.title").localizationCatalog(catalog).locale("nl")).contains(">cart.title<"))
    }

    @Test func localizationReachesThroughComposedViews() {
        let rendered = html(CartSummary(count: 1).localizationCatalog(catalog).locale("nl"))
        #expect(rendered.contains(">Winkelwagen<"))
        // "nl" has no plural entry, so the English source variation applies.
        #expect(rendered.contains(">1 item<"))
    }

    @Test func aNearerLocaleWinsForItsSubtreeOnly() {
        let rendered = html(
            VStack {
                Text("cart.title")
                Text("cart.title").locale("fr")
                Text("cart.title")
            }
            .localizationCatalog(catalog)
            .locale("nl")
        )
        let texts = rendered.split(separator: ">").compactMap { $0.split(separator: "<").first }.map(String.init)
        #expect(texts.filter { ["Cart", "Winkelwagen", "Panier"].contains($0) } == ["Winkelwagen", "Panier", "Winkelwagen"])
    }

    @Test func nothingLeaksOutOfATraversal() {
        _ = html(Text("cart.title").localizationCatalog(catalog).locale("nl"))
        #expect(html(Text("cart.title")).contains(">cart.title<"))
        // A sibling after a localized subtree is unaffected.
        let rendered = html(VStack {
            Text("cart.title").localizationCatalog(catalog).locale("nl")
            Text("cart.title")
        })
        #expect(rendered.contains(">Winkelwagen<"))
        #expect(rendered.contains(">cart.title<"))
    }

    /// The localization travels in `ViewContext`, not in shared storage, so renders in
    /// different locales do not see each other's locale.
    ///
    /// Only primitives are rendered here: lowering a composed view's `body` goes
    /// through the core's shared, unsynchronized state and environment storage, which
    /// is not safe to use from several threads whatever the localization does.
    @Test func concurrentRendersDoNotShareALocale() async {
        await withTaskGroup(of: Bool.self) { group in
            for index in 0..<200 {
                group.addTask {
                    let (locale, expected): (LocaleIdentifier, String) = [("nl", "Winkelwagen"), ("fr", "Panier"), ("en", "Cart")][index % 3]
                    let rendered = html(
                        VStack {
                            Text("cart.title")
                            Button("cart.title") {}
                        }
                        .localizationCatalog(catalog)
                        .locale(locale)
                    )
                    return rendered.components(separatedBy: expected).count == 3
                }
            }
            for await matched in group { #expect(matched) }
        }
    }

    @Test func semanticRoleIsKeptForLocalizedText() {
        let rendered = html(Text("cart.title").semanticRole(.h1).localizationCatalog(catalog).locale("nl"))
        #expect(rendered.contains("<h1"))
        #expect(rendered.contains(">Winkelwagen<"))
        #expect(Text("cart.title", semanticRole: .p).semanticRole == .p)
    }

    @Test func contentIsTheTextWithoutACatalog() {
        #expect(Text("cart.title").content == "cart.title")
        #expect(Text("\(2) items").content == "2 items")
        #expect(Text(verbatim: "plain").content == "plain")
        let localization = LocalizationEnvironment(locale: "nl", resolver: LocalizationResolver(catalog: catalog))
        #expect(Text("cart.title").content(in: localization) == "Winkelwagen")
    }

    /// Content a primitive lowers eagerly is lowered before a localization is known.
    @Test func eagerlyLoweredLabelContentShowsDefaultValues() {
        let rendered = html(Button { Text("Order") }.localizationCatalog(catalog).locale("nl"))
        #expect(rendered.contains("Order"))
        #expect(!rendered.contains("Bestellen"))
    }

    @Test func buttonAndLinkTitlesAreLocalized() {
        // The modifiers wrap the controls in the same expression, so the title must
        // resolve when the control is lowered, not when it is created.
        let rendered = html(
            VStack {
                Button("Order") {}
                Link("Terms", destination: "/terms")
            }
            .localizationCatalog(catalog)
            .locale("nl")
        )
        #expect(rendered.contains("Bestellen"))
        #expect(rendered.contains("Voorwaarden"))
        #expect(!rendered.contains("Order"))

        let untranslated = html(VStack { Button("Order") {}; Link("Terms", destination: "/terms") })
        #expect(untranslated.contains("Order"))
        #expect(untranslated.contains("Terms"))
    }

    @Test func buttonAndLinkStringValuesAreNotLocalized() {
        let title = "Order"
        let rendered = html(
            VStack {
                Button(title) {}
                Link(title, destination: "/order")
            }
            .localizationCatalog(catalog)
            .locale("nl")
        )
        #expect(rendered.contains("Order"))
        #expect(!rendered.contains("Bestellen"))
    }

    @Test func aConfiguredResolverSuppliesItsOwnServices() {
        struct Bracketed: LocalizedNumberFormatter {
            func string(fromDecimal decimal: String, locale: LocaleIdentifier) -> String { "[\(decimal)]" }
        }
        var resolver = LocalizationResolver(catalog: catalog, fallbackLocales: ["fr"])
        resolver.setNumberFormatter(Bracketed())
        #expect(html(Text("\(2) items").localizationResolver(resolver)).contains(">[2] items<"))
        #expect(html(Text("cart.title").localizationResolver(resolver).locale("de")).contains(">Panier<"))
    }
}
