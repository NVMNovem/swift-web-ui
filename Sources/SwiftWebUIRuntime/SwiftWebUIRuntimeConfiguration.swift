/// Options controlling browser-runtime diagnostics.
public struct SwiftWebUIRuntimeConfiguration: Sendable {
    /// Emits one line for every reconciliation patch when enabled.
    public var reconciliationLogging: Bool

    public init(reconciliationLogging: Bool = false) {
        self.reconciliationLogging = reconciliationLogging
    }
}
