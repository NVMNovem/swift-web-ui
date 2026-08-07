//
//  ViewIdentifiable.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 07/08/2026.
//

/// A value that can identify a view across rebuilds.
///
/// Conform domain identifiers to this protocol to use them as `ForEach` keys. Types
/// backed by an `Int` or `String` raw value get an implementation for free.
public protocol ViewIdentifiable {
    var viewIdentityToken: ViewIdentityToken { get }
}

extension Int: ViewIdentifiable {
    public var viewIdentityToken: ViewIdentityToken { .int(self) }
}

extension String: ViewIdentifiable {
    public var viewIdentityToken: ViewIdentityToken { .string(self) }
}

public extension ViewIdentifiable where Self: RawRepresentable, RawValue == Int {
    var viewIdentityToken: ViewIdentityToken { .int(rawValue) }
}

public extension ViewIdentifiable where Self: RawRepresentable, RawValue == String {
    var viewIdentityToken: ViewIdentityToken { .string(rawValue) }
}
