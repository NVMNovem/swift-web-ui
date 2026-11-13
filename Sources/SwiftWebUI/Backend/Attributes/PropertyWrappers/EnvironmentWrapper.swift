//
//  EnvironmentWrapper.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 29/09/2026.
//

/// Reads an object an ancestor placed with ``View/environment(_:)``.
///
/// ```swift
/// struct Checkout: View {
///     @Environment(Basket.self) private var basket
///
///     var body: some View {
///         Button("Order") { basket.submit() }
///     }
/// }
///
/// Checkout().environment(basket)
/// ```
///
/// The environment holds objects keyed by their type, which is the shape SwiftUI's
/// `@Environment(Type.self)` has for an `@Observable` model. A model read here is
/// observed like any other: the mounted root tracks what a `body` reads.
///
/// ## When it resolves
///
/// A view is constructed while its *parent's* `body` runs, and its own `.environment`
/// modifiers are not in effect yet at that point. So the property is answered when it is
/// read, not when it is created: a read while a `body` is being evaluated takes the
/// objects placed by that view's ancestors, and remembers the answer for as long as that
/// view is being lowered. A closure the view hands to a descendant therefore still reads
/// the view's own objects, even under a nearer placement of the same type.
///
/// Code that runs after the traversal reads what was remembered. An action closure is
/// the important case: ``Button`` and ``View/onKeyDown(_:perform:)`` capture the objects in effect
/// where the closure was written and put them back while it runs, so an action can read a
/// property its view's `body` never touched.
///
/// Nothing here inspects the view: there is no reflection, which Embedded Swift does not
/// have.
///
/// Declare the property as optional to read an object that may not be there:
///
/// ```swift
/// @Environment(Basket.self) private var basket: Basket?
/// ```
///
/// ## Values
///
/// A value travels down the tree under a key type that conforms to ``EnvironmentKey``,
/// which also supplies the value read where none was placed:
///
/// ```swift
/// struct AccentKey: EnvironmentKey {
///     static let defaultValue = Color.blue
/// }
///
/// struct Badge: View {
///     @Environment(AccentKey.self) private var accent
///
///     var body: some View {
///         Text("New").foregroundStyle(accent)
///     }
/// }
///
/// Badge().environment(AccentKey.self, .red)
/// ```
///
/// This is SwiftUI's `@Environment(\.accent)` with an `EnvironmentValues` extension.
/// It is keyed by type because key paths are unavailable in Embedded Swift. A value is
/// read under the same rules as an object, and a read never fails.
///
/// ## The locale
///
/// The locale that localized text resolves in is read the same way, and follows the same
/// rules, although it is a value and not an object:
///
/// ```swift
/// @Environment(LocaleIdentifier.self) private var locale
/// ```
@propertyWrapper
public struct Environment<Value> {

    private final class Cell {
        var value: Value?
        /// The lowering that was innermost when `value` was read in a `body`.
        var lowering: Int?
    }

    private let cell = Cell()
    private let typeName: String
    private let lookup: (EnvironmentObjects) -> Value?

    /// Reads a required object. Reading it with none placed is a programming error.
    public init(_ type: Value.Type) where Value: AnyObject {
        typeName = EnvironmentStorage.name(of: type)
        lookup = { $0.object(of: type) }
    }

    /// Reads an object that may not have been placed.
    public init<Object: AnyObject>(_ type: Object.Type) where Value == Object? {
        typeName = EnvironmentStorage.name(of: type)
        lookup = { .some($0.object(of: type)) }
    }

    /// Reads the value placed under `key`, or the key's default.
    ///
    /// ```swift
    /// @Environment(AccentKey.self) private var accent
    /// ```
    public init<Key: EnvironmentKey>(_ key: Key.Type) where Value == Key.Value {
        typeName = EnvironmentStorage.name(of: key)
        lookup = { $0.value(for: key) }
    }

    /// Reads the locale that localized text resolves in.
    ///
    /// ```swift
    /// struct PriceLabel: View {
    ///     @Environment(LocaleIdentifier.self) private var locale
    ///
    ///     var body: some View {
    ///         Text(verbatim: format(price, for: locale))
    ///     }
    /// }
    /// ```
    ///
    /// It is the locale placed with ``View/locale(_:)``. With none placed it is the
    /// source language of the catalog placed with ``View/localizationCatalog(_:)``, and
    /// with no catalog either it is `und`, so the read never fails.
    ///
    /// This is SwiftUI's `@Environment(\.locale)`. It is keyed by type because key
    /// paths are unavailable in Embedded Swift.
    public init(_ type: LocaleIdentifier.Type) where Value == LocaleIdentifier {
        typeName = "LocaleIdentifier"
        lookup = { $0.locale ?? .undetermined }
    }

    public var wrappedValue: Value {
        // Answered in a `body` whose view is still being lowered: this is that view, or a
        // closure it handed down the tree. What it saw then is still the answer.
        if let value = cell.value, let lowering = cell.lowering, EnvironmentStorage.isLowering(lowering) {
            return value
        }
        // A `body` is being evaluated: the objects in effect are the answer, and a new
        // one each time, because the same view value may be lowered again elsewhere.
        if EnvironmentStorage.isEvaluatingBody, let value = lookup(EnvironmentStorage.active) {
            cell.value = value
            cell.lowering = EnvironmentStorage.innermostLowering
            return value
        }
        // After the traversal — an action, typically — what the `body` saw is the answer.
        if let value = cell.value { return value }
        // Never read in a `body`: an action that put its objects back, a view lowered
        // directly, or a read in an initialiser. The objects in effect are the best
        // answer there is.
        if let value = lookup(EnvironmentStorage.active) {
            cell.value = value
            return value
        }
        fatalError("No \(typeName) in the environment. Place one on an ancestor with .environment(_:).")
    }
}

/// The objects and values placed by a view's ancestors, keyed by type.
public struct EnvironmentObjects {
    private var storage: [ObjectIdentifier: AnyObject] = [:]
    /// Values, boxed, keyed by their ``EnvironmentKey`` type.
    private var values: [ObjectIdentifier: AnyObject] = [:]

    /// The locale in effect for the composed view being lowered. `nil` outside one.
    private(set) var locale: LocaleIdentifier?

    public init() {}

    public func object<Object: AnyObject>(of type: Object.Type) -> Object? {
        storage[ObjectIdentifier(type)] as? Object
    }

    /// The value placed under `key`, or the key's default.
    public func value<Key: EnvironmentKey>(for key: Key.Type) -> Key.Value {
        // The key decides the value's type, so a box under it always holds one.
        guard let box = values[EnvironmentKeyToken<Key>.identifier] else { return Key.defaultValue }
        return unsafeDowncast(box, to: EnvironmentValueBox<Key.Value>.self).value
    }

    func settingValue<Key: EnvironmentKey>(_ value: Key.Value, for key: Key.Type) -> EnvironmentObjects {
        var copy = self
        copy.values[EnvironmentKeyToken<Key>.identifier] = EnvironmentValueBox(value)
        return copy
    }

    func settingLocale(_ locale: LocaleIdentifier) -> EnvironmentObjects {
        var copy = self
        copy.locale = locale
        return copy
    }

    func inserting<Object: AnyObject>(_ object: Object) -> EnvironmentObjects {
        var copy = self
        copy.storage[ObjectIdentifier(Object.self)] = object
        return copy
    }
}

/// Names an ``EnvironmentKey`` in the value store.
///
/// Embedded Swift cannot take the metatype of a struct key, so `ObjectIdentifier(Key.self)`
/// is not available. A class specialized on the key is a class, and each
/// specialization has metadata of its own, so its identifier names the key.
final class EnvironmentKeyToken<Key: EnvironmentKey> {
    static var identifier: ObjectIdentifier { ObjectIdentifier(EnvironmentKeyToken<Key>.self) }
}

/// Holds an environment value as an object, so values of every type share one store.
final class EnvironmentValueBox<Value> {
    let value: Value
    init(_ value: Value) { self.value = value }
}

/// The objects in effect for the `body` currently being evaluated.
///
/// Scoped the way ``StateSlotStorage``'s view scope is: a writer sets it around its
/// content's traversal and restores it afterwards, so it is always the objects placed by
/// the ancestors of the view being lowered. A traversal is synchronous and the browser
/// has one thread, which is what `nonisolated(unsafe)` relies on.
enum EnvironmentStorage {
    nonisolated(unsafe) static var active = EnvironmentObjects()

    static func with<Result>(_ objects: EnvironmentObjects, _ body: () -> Result) -> Result {
        let previous = active
        active = objects
        defer { active = previous }
        return body()
    }

    /// Whether a view's `body` getter is running right now.
    ///
    /// True only for the getter itself, not while its result is lowered.
    nonisolated(unsafe) private(set) static var isEvaluatingBody = false

    /// One entry per composed view whose `body` is being evaluated or lowered,
    /// outermost first.
    nonisolated(unsafe) private static var lowerings: [Int] = []
    nonisolated(unsafe) private static var nextLowering = 0

    static var innermostLowering: Int? { lowerings.last }

    static func isLowering(_ lowering: Int) -> Bool {
        lowerings.contains(lowering)
    }

    /// Evaluates a view's `body` and lowers the result.
    ///
    /// The two steps are told apart so that an ``Environment`` read can distinguish a
    /// view reading its own environment, in `evaluate`, from a closure of that view
    /// being called while its descendants are lowered, in `lower`.
    ///
    /// `locale` is the locale this view's text resolves in. It is made readable for the
    /// duration, which is the only moment the traversal's ``ViewContext`` and the
    /// storage a `body` can reach are both at hand. Only composed views pass through
    /// here, so lowering primitives alone still touches no shared storage.
    static func lowering<Body>(
        locale: LocaleIdentifier,
        evaluate: () -> Body,
        lower: (Body) -> ViewNode
    ) -> ViewNode {
        nextLowering &+= 1
        lowerings.append(nextLowering)
        let outer = active
        active = outer.settingLocale(locale)
        defer {
            active = outer
            lowerings.removeLast()
        }

        let previous = isEvaluatingBody
        isEvaluatingBody = true
        let body = evaluate()
        isEvaluatingBody = previous
        return lower(body)
    }

    /// Wraps an action so that it runs with the objects in effect right now.
    ///
    /// Call it where the action is handed over, which is inside the `body` of the view
    /// that wrote the closure: those are the objects that view's ``Environment``
    /// properties mean.
    static func capturing(_ action: @escaping () -> Void) -> () -> Void {
        let objects = active
        return { with(objects, action) }
    }

    /// Wraps a function so that it runs with the objects in effect right now.
    ///
    /// The one-argument form of ``capturing(_:)``, for handlers that are handed
    /// something — a drop's `DropInfo` — and answer something back.
    static func capturing<Input, Output>(_ body: @escaping (Input) -> Output) -> (Input) -> Output {
        let objects = active
        return { input in with(objects) { body(input) } }
    }

    /// Wraps a producer so that it runs with the objects in effect right now.
    static func capturing<Output>(_ body: @escaping () -> Output) -> () -> Output {
        let objects = active
        return { with(objects, body) }
    }

    /// A type's name for a diagnostic. Embedded Swift cannot describe a type.
    static func name<T>(of type: T.Type) -> String {
        #if hasFeature(Embedded)
        "required object"
        #else
        String(describing: type)
        #endif
    }
}
