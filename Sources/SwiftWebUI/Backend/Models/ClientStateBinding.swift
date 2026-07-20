//
//  ClientStateBinding.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 28/06/2026.
//

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
