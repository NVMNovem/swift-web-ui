//
//  RuntimeDialogStylesheet.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 28/08/2026.
//

@_spi(Rendering) import SwiftWebUI

/// The runtime's own stylesheet, installed ahead of every application stylesheet.
///
/// A `::backdrop` is a pseudo-element and cannot be reached by an inline style,
/// so it is the one piece of dialog presentation that has to be a named rule
/// rather than an element declaration. It is coloured through a custom property
/// so an application can theme it, and it is installed first so an application
/// stylesheet can override it outright.
enum RuntimeDialogStylesheet {
    static let css = """
    .\(dialogBackdropClassName)::backdrop {
      background: var(--swiftwebui-dialog-backdrop, rgba(0, 0, 0, 0.45));
    }
    """
}

extension RuntimeResources {
    /// The runtime's own stylesheets, ahead of this value's application ones.
    ///
    /// Installed by ``mount(_:in:resources:configuration:)``. Order is the point:
    /// SwiftWebUI's defaults come first so an application's rules win.
    func withRuntimeStylesheets() -> RuntimeResources {
        RuntimeResources(stylesheets: [.inline(RuntimeDialogStylesheet.css)] + stylesheets)
    }
}
