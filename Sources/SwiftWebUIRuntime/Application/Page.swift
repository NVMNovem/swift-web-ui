//
//  Page.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

import SwiftWebUI

/// A scene that shows one view tree in the browser document.
///
/// ```swift
/// Page {
///     RootView()
/// }
/// .stylesheet(.external("styles.css"))
/// ```
///
/// `Page` is the web's counterpart to SwiftUI's `WindowGroup`. It is named for what a
/// browser shows: one document at one address.
///
/// The content is mounted into the element whose `id` is ``mountPoint``, `"app"` unless
/// ``mountPoint(_:)`` names another. The document that `swift package web` generates
/// carries that element; a hand-written document has to.
///
/// A page installs its stylesheets, in the order they were added, before the first
/// mount, and they outlive every rerender. See ``RuntimeResources``.
public struct Page<Content: View>: Scene {
    /// The view tree this page shows.
    public let content: Content

    /// The `id` of the element the content is mounted into.
    public private(set) var mountPoint: String = "app"

    /// The stylesheets installed before the content is mounted.
    public private(set) var resources: RuntimeResources = .init()

    /// The diagnostics the runtime is asked for.
    public private(set) var configuration: SwiftWebUIRuntimeConfiguration = .init()

    /// Creates a page that shows `content`.
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    /// Adds a stylesheet that is installed before the page's content is mounted.
    ///
    /// Stylesheets are installed in the order they are added, so a later one overrides
    /// an earlier one.
    public func stylesheet(_ stylesheet: RuntimeStylesheet) -> Page {
        var page = self
        page.resources.stylesheets.append(stylesheet)
        return page
    }

    /// Names the element the page's content is mounted into.
    ///
    /// The default is `"app"`. The element has to exist in the document before the
    /// WebAssembly bundle starts.
    public func mountPoint(_ elementID: String) -> Page {
        var page = self
        page.mountPoint = elementID
        return page
    }

    /// Prints one line for every reconciliation patch the runtime applies.
    public func reconciliationLogging(_ isEnabled: Bool = true) -> Page {
        var page = self
        page.configuration.reconciliationLogging = isEnabled
        return page
    }

    public func _mountScene() {
        mount(content, in: mountPoint, resources: resources, configuration: configuration)
    }
}
