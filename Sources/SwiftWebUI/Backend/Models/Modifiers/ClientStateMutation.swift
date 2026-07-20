//
//  ClientStateMutation.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public struct ClientStateMutation: Hashable, Sendable {
    public let target: ClientStateTarget
    public let value: ClientValue

    public init(target: ClientStateTarget, value: ClientValue) {
        self.target = target
        self.value = value
    }
}
