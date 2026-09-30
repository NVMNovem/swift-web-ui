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
/// modifiers are not in effect yet at that point. So the wrapper is filled in just before
/// the view's own `body` is evaluated, from the objects placed by its ancestors — which is
/// also what lets an action closure read it long after the traversal has finished.
///
/// Declare the property as optional to read an object that may not be there:
///
/// ```swift
/// @Environment(Basket.self) private var basket: Basket?
/// ```
@propertyWrapper
public struct Environment<Value> {

    private final class Cell {
        var value: Value?
    }

    private let cell = Cell()
    private let typeName: String
    private let lookup: (EnvironmentObjects) -> Value?

    /// Reads a required object. Reading it with none placed is a programming error.
    public init(_ type: Value.Type) where Value: AnyObject {
        typeName = String(describing: type)
        lookup = { $0.object(of: type) }
    }

    /// Reads an object that may not have been placed.
    public init<Object: AnyObject>(_ type: Object.Type) where Value == Object? {
        typeName = String(describing: type)
        lookup = { .some($0.object(of: type)) }
    }

    public var wrappedValue: Value {
        if let value = cell.value { return value }
        // Outside a resolved traversal — a view lowered directly, or read in its own
        // initialiser — the objects in effect are the best answer there is.
        if let value = lookup(EnvironmentStorage.active) {
            cell.value = value
            return value
        }
        fatalError("No \(typeName) in the environment. Place one on an ancestor with .environment(_:).")
    }
}

extension Environment: EnvironmentResolving {
    func resolve(from objects: EnvironmentObjects) {
        cell.value = lookup(objects)
    }
}

/// The objects placed by a view's ancestors, keyed by type.
public struct EnvironmentObjects {
    private var storage: [ObjectIdentifier: AnyObject] = [:]

    public init() {}

    public func object<Object: AnyObject>(of type: Object.Type) -> Object? {
        storage[ObjectIdentifier(type)] as? Object
    }

    func inserting<Object: AnyObject>(_ object: Object) -> EnvironmentObjects {
        var copy = self
        copy.storage[ObjectIdentifier(Object.self)] = object
        return copy
    }
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
}

/// A stored property that reads the environment.
protocol EnvironmentResolving {
    func resolve(from objects: EnvironmentObjects)
}

/// Fills in a view's ``Environment`` properties before its `body` runs.
enum EnvironmentResolution {

    /// Whether a view type declares any ``Environment`` property, so that the reflection
    /// is paid once per type and not at all for the views that declare none.
    nonisolated(unsafe) private static var declaresEnvironment: [ObjectIdentifier: Bool] = [:]

    static func resolve<V: View>(_ view: V) {
        let type = ObjectIdentifier(V.self)
        if declaresEnvironment[type] == false { return }

        var found = false
        for child in Mirror(reflecting: view).children {
            guard let property = child.value as? EnvironmentResolving else { continue }
            property.resolve(from: EnvironmentStorage.active)
            found = true
        }
        declaresEnvironment[type] = found
    }
}
