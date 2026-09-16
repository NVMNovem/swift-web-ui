//
//  TableColumn.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 16/09/2026.
//

import SwiftCSS

/// One column of a ``Table``: a header, a way to build a cell from a row, and
/// optionally a way to order rows by it.
///
/// ```swift
/// TableColumn("Name", value: { $0.name }) { product in
///     VStack(alignment: .leading) {
///         Text(product.name)
///         Text(product.slug)
///     }
/// }
/// ```
///
/// The cell builder is stored as a closure producing a ``ViewNode`` rather than a
/// generic view, because the columns of one table have different content types and
/// their rows are not known until the table is lowered. The closure stays
/// renderer-neutral: it produces the same semantic node any other view produces,
/// and it is evaluated with the cell's real ``ViewContext``, so `State` declared
/// inside a cell keeps its slot across rebuilds.
public struct TableColumn<Row> {
    /// The name a ``TableSort`` uses for this column. Defaults to the title.
    public let id: String
    public let title: String
    public let width: SwiftCSS.Length?
    public let alignment: TextAlignment

    /// Orders two rows ascending, for a column that can be sorted by at all.
    let comparator: ((Row, Row) -> Bool)?
    let content: (Row, ViewContext) -> ViewNode

    init(
        id: String,
        title: String,
        width: SwiftCSS.Length?,
        alignment: TextAlignment,
        comparator: ((Row, Row) -> Bool)?,
        content: @escaping (Row, ViewContext) -> ViewNode
    ) {
        self.id = id
        self.title = title
        self.width = width
        self.alignment = alignment
        self.comparator = comparator
        self.content = content
    }
}

public extension TableColumn {
    /// A column that shows arbitrary content and cannot be sorted by.
    init<Content: View>(
        _ title: String,
        id: String? = nil,
        width: SwiftCSS.Length? = nil,
        alignment: TextAlignment = .leading,
        @ViewBuilder content: @escaping (Row) -> Content
    ) {
        self.init(
            id: id ?? title,
            title: title,
            width: width,
            alignment: alignment,
            comparator: nil,
            content: { row, context in content(row).makeViewNode(in: context) }
        )
    }

    /// A column that shows arbitrary content and sorts on a comparable value.
    ///
    /// `value` is read while sorting, not while rendering: a column may sort on
    /// something its cell never shows — a raw amount behind a formatted one, or a
    /// date behind "yesterday".
    init<Content: View, Value: Comparable>(
        _ title: String,
        id: String? = nil,
        width: SwiftCSS.Length? = nil,
        alignment: TextAlignment = .leading,
        value: @escaping (Row) -> Value,
        @ViewBuilder content: @escaping (Row) -> Content
    ) {
        self.init(
            id: id ?? title,
            title: title,
            width: width,
            alignment: alignment,
            comparator: { value($0) < value($1) },
            content: { row, context in content(row).makeViewNode(in: context) }
        )
    }

    /// A column that shows arbitrary content and sorts with its own comparator.
    ///
    /// Use this for an order no single comparable value expresses — a tie broken
    /// by a second field, or a "missing sorts last" rule.
    init<Content: View>(
        _ title: String,
        id: String? = nil,
        width: SwiftCSS.Length? = nil,
        alignment: TextAlignment = .leading,
        sortBy comparator: @escaping (Row, Row) -> Bool,
        @ViewBuilder content: @escaping (Row) -> Content
    ) {
        self.init(
            id: id ?? title,
            title: title,
            width: width,
            alignment: alignment,
            comparator: comparator,
            content: { row, context in content(row).makeViewNode(in: context) }
        )
    }

    /// A column of plain text, sorted by the text it shows.
    init(
        _ title: String,
        id: String? = nil,
        width: SwiftCSS.Length? = nil,
        alignment: TextAlignment = .leading,
        value: @escaping (Row) -> String
    ) {
        self.init(
            id: id ?? title,
            title: title,
            width: width,
            alignment: alignment,
            comparator: { value($0) < value($1) },
            content: { row, context in Text(value(row)).makeViewNode(in: context) }
        )
    }
}
