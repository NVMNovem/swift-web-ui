//
//  ResourceScope.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public enum ResourceScope: Equatable, Sendable {
    
    case global
    case component(String)
    case page(String)
}
