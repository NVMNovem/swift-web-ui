//
//  ClientStateBinding.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 28/06/2026.
//

/// Metadata that connects a SwiftWebUI binding to generated browser state.
public struct ClientStateBinding: Equatable, Sendable {
    
    public var key: String
    public var initialValue: String

    public init(key: String, initialValue: String) {
        self.key = key
        self.initialValue = initialValue
    }
}
