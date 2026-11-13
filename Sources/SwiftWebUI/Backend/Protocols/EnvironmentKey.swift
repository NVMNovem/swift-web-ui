//
//  EnvironmentKey.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 13/11/2026.
//

/// A key for a value that travels down the view tree.
///
/// ```swift
/// struct AccentKey: EnvironmentKey {
///     static let defaultValue = Color.blue
/// }
/// ```
///
/// Place a value with ``View/environment(_:_:)`` and read it with
/// `@Environment(AccentKey.self)`. Where no ancestor placed one, the read answers
/// ``defaultValue``.
///
/// This is SwiftUI's `EnvironmentKey`. SwiftUI then names the value with a key path
/// into `EnvironmentValues`; key paths are unavailable in Embedded Swift, so here the
/// key type itself is the name, as `LocaleIdentifier.self` is for the locale.
public protocol EnvironmentKey {
    /// The type of value this key carries.
    associatedtype Value

    /// The value read where no ancestor placed one.
    static var defaultValue: Value { get }
}
