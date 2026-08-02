//
//  WebStateValue.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

/// Canonical browser-facing key for renderer-neutral client-state intent.
@_spi(Rendering)
public func webStateKey(_ target: ClientStateTarget) -> String {
    switch target {
    case .state(let identity):
        "state-\(String(UInt(bitPattern: identity.objectIdentifier), radix: 16))"
    case .named(let key):
        key
    }
}

/// Canonical browser-facing value for renderer-neutral client-state intent.
@_spi(Rendering)
public func webClientValueString(_ value: ClientValue) -> String {
    switch value {
    case .string(let value): value
    case .integer(let value): String(value)
    case .boolean(let value): value ? "true" : "false"
    }
}
