//
//  StyleResource.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

/// A rendered CSS resource collected from SwiftWebUI modifiers.
public struct StyleResource {
    
    public var id: String
    public var scope: ResourceScope
    public var content: String

    public init(id: String, scope: ResourceScope, content: String) {
        self.id = id
        self.scope = scope
        self.content = content
    }
}
