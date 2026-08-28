//
//  KeyAction.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 28/08/2026.
//

/// One key-down handler attached to an element.
///
/// `key` is the DOM's own `KeyboardEvent.key` string — `"Escape"`, `"Enter"`,
/// `"ArrowDown"` — rather than a SwiftWebUI enum, which would need extending for
/// every key a caller ever wants.
@_spi(Rendering)
public struct KeyAction {
    public let key: String
    public let action: ActionIntent

    public init(key: String, action: ActionIntent) {
        self.key = key
        self.action = action
    }
}
