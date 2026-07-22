//
//  RuntimeStylesheet.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 22/07/2026.
//

/// A stylesheet installed into the browser document head for a runtime application.
public enum RuntimeStylesheet: Sendable, Equatable {
    /// A stylesheet URL resolved by the browser relative to the served document URL.
    case external(String)

    /// CSS text installed unchanged in a `style` element.
    case inline(String)
}
