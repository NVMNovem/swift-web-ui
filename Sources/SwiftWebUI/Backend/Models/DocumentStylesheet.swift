//
//  DocumentStylesheet.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 14/11/2026.
//

/// A stylesheet for the document head.
///
/// A ``View/stylesheet(_:)`` modifier places one while its view is shown, and
/// `SwiftWebUIRuntime`'s `Page` installs its own before the first mount, where it is
/// spelled `RuntimeStylesheet`.
///
/// Application build tooling copies the file an external stylesheet names. This value
/// only describes what the head links to.
public enum DocumentStylesheet: Sendable, Equatable {
    /// A stylesheet URL resolved by the browser relative to the served document URL.
    case external(String)

    /// CSS text installed unchanged in a `style` element.
    case inline(String)
}
