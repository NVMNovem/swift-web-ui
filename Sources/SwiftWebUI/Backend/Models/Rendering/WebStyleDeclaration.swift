//
//  WebStyleDeclaration.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

/// A concrete CSS property/value pair shared by all rendering backends.
@_spi(Rendering)
public struct WebStyleDeclaration: Equatable, Sendable {
    public let name: String
    public let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

/// A backend-neutral alternate style set whose generated class is exposed through an attribute.
///
/// Static client-state controls use this to switch styles without putting generated class hashes
/// or serialized CSS in the shared core model.
@_spi(Rendering)
public struct WebStyleVariant: Equatable, Sendable {
    public let classAttributeName: String
    public let styles: [WebStyleDeclaration]

    public init(classAttributeName: String, styles: [WebStyleDeclaration]) {
        self.classAttributeName = classAttributeName
        self.styles = styles
    }
}
