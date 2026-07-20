//
//  WebAttribute.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

/// A concrete HTML attribute intent shared by all rendering backends.
@_spi(Rendering)
public struct WebAttribute: Equatable, Sendable {
    public let name: String
    public let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}
