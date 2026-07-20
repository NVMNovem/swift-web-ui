public enum ClientValue: Hashable, Sendable {
    case string(String)
    case integer(Int)
    case boolean(Bool)
}

public protocol ClientStateValue {
    var clientValue: ClientValue { get }
}

extension String: ClientStateValue {
    public var clientValue: ClientValue { .string(self) }
}

extension Int: ClientStateValue {
    public var clientValue: ClientValue { .integer(self) }
}

extension Bool: ClientStateValue {
    public var clientValue: ClientValue { .boolean(self) }
}

public struct StateIdentity: Hashable, Sendable {
    public let objectIdentifier: ObjectIdentifier

    public init(_ objectIdentifier: ObjectIdentifier) {
        self.objectIdentifier = objectIdentifier
    }
}

public enum ClientStateTarget: Hashable, Sendable {
    case state(StateIdentity)
    case named(String)
}

public struct ClientStateBinding: Hashable, Sendable {
    public let target: ClientStateTarget
    public let initialValue: ClientValue

    public init(target: ClientStateTarget, initialValue: ClientValue) {
        self.target = target
        self.initialValue = initialValue
    }
}

public struct ClientStateMutation: Hashable, Sendable {
    public let target: ClientStateTarget
    public let value: ClientValue

    public init(target: ClientStateTarget, value: ClientValue) {
        self.target = target
        self.value = value
    }
}

/// The renderer-neutral invalidation hook used by the first browser runtime.
///
/// This deliberately supports one installed callback. A future mounted state-slot
/// system will replace this proof-of-concept mechanism.
@_spi(Runtime)
public enum ViewInvalidation {
    nonisolated(unsafe) private static var callback: (() -> Void)?

    public static func install(_ callback: @escaping () -> Void) {
        self.callback = callback
    }

    public static func clear() {
        callback = nil
    }

    static func invalidate() {
        callback?()
    }
}

@propertyWrapper
public struct State<Value> {
    private final class Storage {
        var value: Value
        init(_ value: Value) { self.value = value }
    }

    private let storage: Storage

    public init(wrappedValue: Value) {
        storage = Storage(wrappedValue)
    }

    public var wrappedValue: Value {
        get { storage.value }
        nonmutating set {
            storage.value = newValue
            ViewInvalidation.invalidate()
        }
    }

    public var projectedValue: Binding<Value> {
        Binding(
            get: { storage.value },
            set: {
                storage.value = $0
                ViewInvalidation.invalidate()
            },
            stateIdentity: StateIdentity(ObjectIdentifier(storage))
        )
    }
}

public struct Binding<Value> {
    private let getter: () -> Value
    private let setter: (Value) -> Void
    public let stateIdentity: StateIdentity?

    public init(
        get: @escaping () -> Value,
        set: @escaping (Value) -> Void,
        stateIdentity: StateIdentity? = nil
    ) {
        getter = get
        setter = set
        self.stateIdentity = stateIdentity
    }

    public var wrappedValue: Value {
        get { getter() }
        nonmutating set { setter(newValue) }
    }
}

func clientValue<Value: ClientStateValue>(_ value: Value) -> ClientValue {
    value.clientValue
}

func clientValue<Value: RawRepresentable>(_ value: Value) -> ClientValue
where Value.RawValue == String {
    .string(value.rawValue)
}

func clientValue<Value: RawRepresentable>(_ value: Value) -> ClientValue
where Value.RawValue == Int {
    .integer(value.rawValue)
}
