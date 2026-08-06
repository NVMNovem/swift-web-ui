//
//  WebNamedValue.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 06/08/2026.
//

/// A rendering value addressed by name, where a repeated name is a redeclaration.
protocol WebNamedValue {
    var name: String { get }
}

extension WebAttribute: WebNamedValue {}
extension WebStyleDeclaration: WebNamedValue {}

extension Array where Element: WebNamedValue {
    /// Keeps only the last declaration of each name, at the position it was last declared.
    ///
    /// Modifiers compose by appending, so pairs like `.buttonStyle(.primary).background(...)` or
    /// `.font(.callout).bold()` emit the same property twice. Browsers resolve that by letting the
    /// last declaration win; collapsing it here gives every backend — static CSS, DOM mounting and
    /// reconciliation — one value per name instead of each resolving duplicates its own way.
    /// The *last* position is the one that survives, because a shorthand that redeclares what a
    /// longhand set (`border-color` then `border`) only wins when it stays last.
    func lastDeclarationPerName() -> [Element] {
        var lastIndexByName: [String: Int] = [:]
        for (index, element) in enumerated() { lastIndexByName[element.name] = index }
        guard lastIndexByName.count < count else { return self }
        return enumerated().filter { lastIndexByName[$0.element.name] == $0.offset }.map(\.element)
    }
}
