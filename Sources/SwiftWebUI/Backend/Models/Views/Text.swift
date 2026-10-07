//
//  Text.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

/// A run of text.
///
/// As in SwiftUI, a string literal is a localization key and a `String` value is shown
/// as it is:
///
/// ```swift
/// Text("cart.title")          // looked up in the catalog
/// Text("\(count) items")      // looked up as "%lld items", pluralized per locale
/// Text(product.name)          // shown verbatim
/// Text(verbatim: "v1.0")      // a literal that must not be localized
/// ```
///
/// Localized text is resolved while the view is lowered, with the catalog and locale
/// placed by ``View/localizationCatalog(_:)`` and ``View/locale(_:)``. With no catalog,
/// or no entry for the key, the literal itself is shown with its interpolations
/// formatted, so text that was never translated renders exactly as written.
public struct Text: View {
    public typealias Body = Never

    enum Storage {
        case verbatim(String)
        case localized(LocalizedResource)
    }

    let storage: Storage
    public private(set) var semanticRole: SemanticRole

    /// Creates text that is looked up in the localization catalog.
    ///
    /// A string literal or interpolation selects this initializer.
    public init(_ resource: LocalizedResource, semanticRole: SemanticRole = .span) {
        self.storage = .localized(resource)
        self.semanticRole = semanticRole
    }

    /// Creates text that shows a string value without localizing it.
    // Disfavored, as in SwiftUI, so that a string literal selects the localized
    // initializer rather than this one.
    @_disfavoredOverload
    public init<S: StringProtocol>(_ content: S, semanticRole: SemanticRole = .span) {
        self.storage = .verbatim(String(content))
        self.semanticRole = semanticRole
    }

    /// Creates text that shows a string literal without localizing it.
    public init(verbatim content: String, semanticRole: SemanticRole = .span) {
        self.storage = .verbatim(content)
        self.semanticRole = semanticRole
    }

    /// The text without a catalog: the verbatim string, or the default value of a
    /// localized text with its interpolations formatted.
    ///
    /// What a localized text renders as depends on the catalog and locale placed around
    /// it, which are only known while the view is lowered.
    public var content: String {
        content(in: LocalizationEnvironment())
    }

    func content(in localization: LocalizationEnvironment) -> String {
        switch storage {
        case .verbatim(let content): content
        case .localized(let resource): localization.string(for: resource)
        }
    }

    public func semanticRole(_ role: SemanticRole) -> Text {
        var copy = self
        copy.semanticRole = role
        return copy
    }

    public var body: Never { fatalError("Text primitive body unavailable") }
    public func makeViewNode(in context: ViewContext) -> ViewNode {
        .text(.init(content: content(in: context.localization), semanticRole: semanticRole))
    }
}
