//
//  TableNode.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 16/09/2026.
//

import SwiftCSS

/// A tabular grid of already-lowered cells.
///
/// Rows arrive in the order they are to be shown: ``Table`` applies the active
/// sort while it lowers, so the node carries a decided list rather than a
/// comparator the renderers would have to run. What remains renderer-neutral is
/// the *presentation* of the sort — which column is active, which way it runs,
/// and what clicking a header asks for.
public struct TableNode {
    /// One column's header, and how its cells are laid out.
    public struct Column {
        public let id: String
        public let title: String
        public let width: SwiftCSS.Length?
        public let alignment: TextAlignment
        /// Which way this column runs, when it is the one being sorted by.
        public let sortOrder: TableSortOrder?
        /// What clicking this header asks for, when the column can be sorted at all.
        public let sortAction: ActionIntent?

        public init(
            id: String,
            title: String,
            width: SwiftCSS.Length?,
            alignment: TextAlignment,
            sortOrder: TableSortOrder?,
            sortAction: ActionIntent?
        ) {
            self.id = id
            self.title = title
            self.width = width
            self.alignment = alignment
            self.sortOrder = sortOrder
            self.sortAction = sortAction
        }
    }

    /// One row's cells, in column order.
    public struct Row {
        public let cells: [ViewNode]
        public let background: Background?

        public init(cells: [ViewNode], background: Background?) {
            self.cells = cells
            self.background = background
        }
    }

    public let columns: [Column]
    public let rows: [Row]
    public let showsHeader: Bool
    /// Whether the header stays put while the rows scroll under it.
    public let headerIsSticky: Bool

    public init(
        columns: [Column],
        rows: [Row],
        showsHeader: Bool,
        headerIsSticky: Bool
    ) {
        self.columns = columns
        self.rows = rows
        self.showsHeader = showsHeader
        self.headerIsSticky = headerIsSticky
    }
}
