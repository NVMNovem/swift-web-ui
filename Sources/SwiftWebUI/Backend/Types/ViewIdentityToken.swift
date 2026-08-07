//
//  ViewIdentityToken.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 07/08/2026.
//

/// A concrete identity value for one element of a keyed collection.
///
/// The Embedded core cannot store `AnyHashable`, so keyed identity is reduced to a
/// closed set of concrete representations instead of an existential.
public enum ViewIdentityToken: Hashable, Sendable {
    case int(Int)
    case string(String)
}
