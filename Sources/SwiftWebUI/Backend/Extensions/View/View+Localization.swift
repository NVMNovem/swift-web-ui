//
//  View+Localization.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 07/10/2026.
//

public extension View {

    /// Sets the locale that localized text inside this view resolves in.
    ///
    /// ```swift
    /// CheckoutPage()
    ///     .localizationCatalog(.localizable)
    ///     .locale("nl-BE")
    /// ```
    ///
    /// The catalog is searched for the locale itself, then for its less specific forms
    /// (`nl-BE`, then `nl`), then for the catalog's source language. A locale placed
    /// further in replaces this one for that subtree only. With no locale placed, text
    /// resolves in the catalog's source language; the process and browser locale are
    /// never consulted implicitly.
    ///
    /// This is SwiftUI's `.environment(\.locale, _:)`. It is spelled as a modifier
    /// because key paths are unavailable in Embedded Swift.
    func locale(_ locale: LocaleIdentifier) -> LocalizationWriter<Self> {
        LocalizationWriter(content: self, change: .locale(locale))
    }

    /// Sets the catalog that localized text inside this view is looked up in.
    ///
    /// A catalog is usually the property that `SwiftLocalizationPlugin` generates from
    /// an `.xcstrings` file, such as `LocalizationCatalog.localizable`. A catalog placed
    /// further in replaces this one for that subtree only.
    ///
    /// SwiftUI has no counterpart: it reads catalogs from a bundle, which a web
    /// application does not have.
    func localizationCatalog(_ catalog: LocalizationCatalog) -> LocalizationWriter<Self> {
        LocalizationWriter(content: self, change: .resolver(LocalizationResolver(catalog: catalog)))
    }

    /// Sets a configured resolver for localized text inside this view.
    ///
    /// Use this instead of ``localizationCatalog(_:)`` to supply a number formatter,
    /// plural rules, or fallback locales of your own.
    func localizationResolver(_ resolver: LocalizationResolver) -> LocalizationWriter<Self> {
        LocalizationWriter(content: self, change: .resolver(resolver))
    }
}

/// A view whose content resolves localized text with a different locale or catalog.
///
/// Adds nothing to the tree it lowers to, so placing a locale never changes the DOM
/// structure, only the text in it. The localization travels down the traversal in
/// ``ViewContext``, so concurrent renders in different locales do not interfere.
///
/// Content that a primitive lowers eagerly in a detached context — the content closure
/// of ``Button`` and ``Link``, a ``Tab`` label — is lowered before any localization is
/// known and shows its default values. Their string-literal titles are localized.
public struct LocalizationWriter<Content: View>: View {
    public typealias Body = Never

    enum Change {
        case locale(LocaleIdentifier)
        case resolver(LocalizationResolver)
    }

    let content: Content
    let change: Change

    public var body: Never { fatalError("LocalizationWriter primitive body unavailable") }

    public func makeViewNode(in context: ViewContext) -> ViewNode {
        var localization = context.localization
        switch change {
        case .locale(let locale): localization.locale = locale
        case .resolver(let resolver): localization.resolver = resolver
        }
        return content.makeViewNode(in: context.localized(localization))
    }
}
