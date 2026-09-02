//
//  LoweredView.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 01/09/2026.
//

/// Document-level presentation discovered while lowering a view tree.
@_spi(Rendering)
public struct ViewDocumentMetadata: Equatable, Sendable {
    public var navigationTitle: String?
    public var navigationIcon: NavigationIcon?

    public init(
        navigationTitle: String? = nil,
        navigationIcon: NavigationIcon? = nil
    ) {
        self.navigationTitle = navigationTitle
        self.navigationIcon = navigationIcon
    }
}

/// The renderer-neutral body tree and document metadata produced together.
///
/// Document metadata deliberately lives beside ``WebNode`` rather than inside
/// it: a `WebNode` always describes mounted or rendered body presentation.
@_spi(Rendering)
public struct LoweredView: @unchecked Sendable {
    public var webNode: WebNode
    public var documentMetadata: ViewDocumentMetadata

    public init(
        webNode: WebNode,
        documentMetadata: ViewDocumentMetadata = .init()
    ) {
        self.webNode = webNode
        self.documentMetadata = documentMetadata
    }
}
