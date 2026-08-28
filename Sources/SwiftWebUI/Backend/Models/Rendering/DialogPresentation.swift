//
//  DialogPresentation.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 28/08/2026.
//

/// How a dialog element is currently presented.
///
/// Presentation is modelled as state carried on the element, the way focus is,
/// rather than as a method a view can call. `showModal()` is imperative and the
/// mounter is declarative, so the mounter and the differ reconcile this value
/// and call into the browser themselves.
public enum DialogPresentation: Hashable, Sendable {
    /// Shown in the browser's top layer, with a backdrop, a focus trap, and an
    /// inert background.
    case modal
    /// Shown in the normal flow, without a backdrop or a focus trap.
    case nonModal
    /// Not shown.
    case dismissed

    /// Whether the browser is showing this dialog.
    public var isPresented: Bool { self != .dismissed }
}

/// The class SwiftWebUI puts on every lowered `dialog` element.
///
/// `::backdrop` is a pseudo-element and cannot be reached by an inline style, so
/// the backdrop has to be a named rule in a stylesheet. This class is what scopes
/// that rule to SwiftWebUI's own dialogs.
@_spi(Rendering)
public let dialogBackdropClassName = "swiftwebui-dialog"
