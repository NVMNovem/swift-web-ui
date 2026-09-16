//
//  TableSort.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 16/09/2026.
//

/// Which way a sorted ``Table`` column runs.
public enum TableSortOrder: String, Hashable, Sendable {
    case ascending
    case descending

    /// The order a second click on the same column asks for.
    public var reversed: TableSortOrder {
        self == .ascending ? .descending : .ascending
    }
}

/// The column a ``Table`` is sorted by, and which way round.
///
/// A table sorts nothing on its own: the value lives in application state and is
/// written back through the binding the table was given, so the sort survives a
/// rebuild and can be restored, persisted, or set from somewhere else entirely.
///
/// The column is named rather than typed, because the columns of one table are
/// heterogeneous and a sort has to outlive the column values it came from. The
/// identifier is ``TableColumn``'s `id`, which defaults to its title.
public struct TableSort: Hashable, Sendable {
    public var columnID: String
    public var order: TableSortOrder

    public init(_ columnID: String, order: TableSortOrder = .ascending) {
        self.columnID = columnID
        self.order = order
    }
}
