//
//  TabControlSupport.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

extension Binding {
    func binding(_ initialValue: ClientValue) -> ClientStateBinding? {
        stateIdentity.map { .init(target: .state($0), initialValue: initialValue) }
    }
}
