import SwiftWebUIStatic

/// The palette, as names for what a colour is for.
///
/// Each token resolves a custom property declared in `Resources/styles.css`, so
/// light and dark stay in the stylesheet — a `@media` rule, which no modifier
/// can state — and a view never spells a hex value.
enum Theme {
    static let background = Color("var(--site-background)")
    static let surface = Color("var(--site-surface)")
    static let border = Color("var(--site-border)")
    static let text = Color("var(--site-text)")
    static let secondaryText = Color("var(--site-text-secondary)")
    static let accent = Color("var(--site-accent)")

    /// The reading column and the gutter that keeps it off a narrow screen's edge.
    static let column = Length.px(960)
    static let gutter = Length.px(20)
}
