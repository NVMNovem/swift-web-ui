//
//  ClientStateValue.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 28/06/2026.
//

public protocol ClientStateValue {
    
    var clientStateValue: String { get }
}

extension String: ClientStateValue {
    
    public var clientStateValue: String { self }
}

extension Int: ClientStateValue {
    
    public var clientStateValue: String { String(self) }
}

extension Bool: ClientStateValue {
    
    public var clientStateValue: String { self ? "true" : "false" }
}

public extension ClientStateValue where Self: RawRepresentable, RawValue == String {
    
    var clientStateValue: String { rawValue }
}

public extension ClientStateValue where Self: RawRepresentable, RawValue == Int {
    
    var clientStateValue: String { String(rawValue) }
}

func clientStateValueString<Value>(_ value: Value) -> String {
    if let clientStateValue = value as? any ClientStateValue {
        return clientStateValue.clientStateValue
    }
    
    return String(describing: value)
}

func clientStateValueString<Value: RawRepresentable>(_ value: Value) -> String where Value.RawValue == String {
    value.rawValue
}

func clientStateValueString<Value: RawRepresentable>(_ value: Value) -> String where Value.RawValue == Int {
    String(value.rawValue)
}
