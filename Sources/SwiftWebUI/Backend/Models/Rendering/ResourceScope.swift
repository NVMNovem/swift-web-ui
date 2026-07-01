//
//  ResourceScope.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

/// Describes where a rendered resource is intended to apply.
public enum ResourceScope: Equatable, Sendable {
    
    case global
    case component(String)
    case page(String)
}
