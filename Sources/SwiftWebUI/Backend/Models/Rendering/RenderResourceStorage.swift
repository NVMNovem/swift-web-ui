//
//  ElementAttributes.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

internal final class RenderResourceStorage {
    
    internal var styleRegistry = StyleRegistry()
    internal var scripts: [ScriptResource] = []
    internal var scriptIDs: Set<String> = []
}
