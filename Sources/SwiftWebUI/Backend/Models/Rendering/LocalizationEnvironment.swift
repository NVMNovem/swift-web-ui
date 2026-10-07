//
//  LocalizationEnvironment.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 07/10/2026.
//

/// The locale and catalog in effect for the views being lowered.
///
/// It travels in ``ViewContext``, not in shared storage, so two traversals on different
/// threads — a server rendering two requests in different languages — cannot see each
/// other's locale.
struct LocalizationEnvironment: Sendable {
    /// The locale placed with ``View/locale(_:)``. When `nil`, text resolves in
    /// the source language of the catalog.
    var locale: LocaleIdentifier?
    /// The resolver placed with ``View/localizationCatalog(_:)`` or
    /// ``View/localizationResolver(_:)``.
    var resolver: LocalizationResolver?

    /// Formats default values when no catalog has been placed.
    private static let fallback = LocalizationResolver(catalog: LocalizationCatalog(sourceLanguage: .undetermined))

    /// The locale text resolves in: the one placed, or else the catalog's source
    /// language, or else `und` when there is no catalog either.
    var effectiveLocale: LocaleIdentifier {
        locale ?? resolver?.catalog.sourceLanguage ?? .undetermined
    }

    /// The text of `resource` for this environment.
    ///
    /// Without a catalog, or when the catalog cannot answer, this is the
    /// resource's default value with its arguments formatted.
    func string(for resource: LocalizedResource) -> String {
        let resolver = resolver ?? Self.fallback
        return resolver.string(for: resource, locale: effectiveLocale)
    }
}
