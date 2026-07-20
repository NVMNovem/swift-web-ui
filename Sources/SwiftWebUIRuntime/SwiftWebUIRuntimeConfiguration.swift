//
//  SwiftWebUIRuntimeConfiguration.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

/// Options controlling browser-runtime diagnostics.
public struct SwiftWebUIRuntimeConfiguration: Sendable {
    /// Emits one line for every reconciliation patch when enabled.
    public var reconciliationLogging: Bool

    public init(reconciliationLogging: Bool = false) {
        self.reconciliationLogging = reconciliationLogging
    }
}
