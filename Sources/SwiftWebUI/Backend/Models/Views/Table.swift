//
//  Table.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 16/09/2026.
//

import SwiftCSS

/// Rows of data shown as columns, with a default look and optional sorting.
///
/// ```swift
/// Table(products, id: { $0.id.uuidString }, sort: $sort) {
///     TableColumn("Name", value: { $0.name }) { product in
///         Text(product.name).font(.system(size: 13, weight: .medium))
///     }
///     TableColumn("Price", width: .px(96), alignment: .trailing, value: { $0.cents }) { product in
///         Text(product.formattedPrice)
///     }
///     TableColumn("On sale", width: .px(80)) { product in
///         Toggle(product)
///     }
/// }
/// .minWidth(.px(980))
/// ```
///
/// A table lowers to a real `table`/`thead`/`tbody` tree, so a screen reader
/// announces rows and columns and the sorted column, and it arrives already
/// wearing a plain default look. Everything that look decides is an ordinary
/// element declaration, so a modifier on the table overrides it: modifiers land on
/// the `table` element itself, which is where `minWidth`, `font`, `background` and
/// `border` mean what they look like they mean. Column width and alignment belong
/// to ``TableColumn``, and the generated class names —
/// `swiftwebui-table`, `swiftwebui-table-header`, `swiftwebui-table-header-cell`,
/// `swiftwebui-table-sort`, `swiftwebui-table-sort-indicator`,
/// `swiftwebui-table-row`, and `swiftwebui-table-cell` — are there for the rules an
/// inline declaration cannot express, such as a hover state.
///
/// ### Sorting
///
/// Sorting is state the application owns. Pass a ``TableSort`` binding and the
/// columns that declare a value or a comparator become header buttons: clicking one
/// sorts by it ascending, clicking the active one turns it round. The table reads
/// the binding while it lowers and orders the rows itself, so nothing else has to
/// keep a sorted copy.
///
/// Rows scroll horizontally the way any wide element does — put the table in a
/// container that scrolls, give it a `minWidth`, and use ``stickyHeader(_:)`` to keep
/// the header in view.
public struct Table<Data: Sequence>: View {
    public typealias Body = Never
    public typealias Row = Data.Element

    public let data: Data
    let identify: ((Row) -> ViewIdentityToken)?
    let columns: [TableColumn<Row>]
    let sort: Binding<TableSort?>?
    var rowBackground: ((Row) -> Background?)?
    var showsHeader: Bool = true
    var headerIsSticky: Bool = false
    var columnLayout: TableColumnLayout?

    init(
        data: Data,
        identify: ((Row) -> ViewIdentityToken)?,
        columns: [TableColumn<Row>],
        sort: Binding<TableSort?>?
    ) {
        self.data = data
        self.identify = identify
        self.columns = columns
        self.sort = sort
    }

    public var body: Never { fatalError("Table primitive body unavailable") }

    public func makeViewNode(in context: ViewContext) -> ViewNode {
        let activeSort = sort?.wrappedValue
        var rows: [TableNode.Row] = []
        for (index, row) in orderedRows(activeSort).enumerated() {
            let rowContext: ViewContext
            if let identify {
                rowContext = context.appending(.identified(identify(row)))
            } else {
                rowContext = context.child(index)
            }
            var cells: [ViewNode] = []
            for (column, cellIndex) in zip(columns, columns.indices) {
                cells.append(column.content(row, rowContext.child(cellIndex)))
            }
            rows.append(.init(cells: cells, background: rowBackground?(row)))
        }

        return .table(.init(
            columns: columns.map { column in
                .init(
                    id: column.id,
                    title: column.title,
                    width: column.width,
                    alignment: column.alignment,
                    sortOrder: activeSort?.columnID == column.id ? activeSort?.order : nil,
                    sortAction: sortAction(for: column, activeSort: activeSort)
                )
            },
            rows: rows,
            showsHeader: showsHeader,
            headerIsSticky: headerIsSticky,
            columnLayout: columnLayout ?? defaultColumnLayout
        ))
    }

    /// How the columns are sized when the table has not been told.
    ///
    /// Declaring a width on a column is a statement that the width matters, and a
    /// browser's own table layout treats it as a suggestion it may exceed — one
    /// long unwrapped line in one cell is enough to take a column far wider than
    /// it was given. So a table with any declared width holds its widths, and a
    /// table with none, having been told nothing, lets its content decide.
    private var defaultColumnLayout: TableColumnLayout {
        columns.contains { $0.width != nil } ? .fixed : .sizedToContent
    }

    /// The rows in the order they are to be shown.
    ///
    /// Sorting happens here rather than in the caller so that a table is declared
    /// from the data as it is held, and so the header and the rows can never
    /// disagree about which column is the sorted one.
    private func orderedRows(_ activeSort: TableSort?) -> [Row] {
        let rows = Array(data)
        guard let activeSort,
              let column = columns.first(where: { $0.id == activeSort.columnID }),
              let comparator = column.comparator
        else { return rows }
        let ascending = rows.sorted(by: comparator)
        return activeSort.order == .ascending ? ascending : Array(ascending.reversed())
    }

    /// What clicking `column`'s header asks for.
    ///
    /// A first click sorts ascending; a click on the column already sorted by turns
    /// it round. A column with no comparator, or a table with no binding to write
    /// to, has no button at all rather than a dead one.
    private func sortAction(for column: TableColumn<Row>, activeSort: TableSort?) -> ActionIntent? {
        guard let sort, column.comparator != nil else { return nil }
        let next = TableSort(
            column.id,
            order: activeSort?.columnID == column.id ? activeSort!.order.reversed : .ascending
        )
        return .closure { sort.wrappedValue = next }
    }
}

// MARK: - Creating a table

public extension Table {
    /// Creates an unkeyed table.
    ///
    /// Rows are identified by position, so inserting or removing one shifts the
    /// state of every row after it. Prefer ``init(_:id:sort:columns:)`` when cells
    /// own state.
    init(
        _ data: Data,
        sort: Binding<TableSort?>? = nil,
        @TableColumnBuilder<Row> columns: () -> [TableColumn<Row>]
    ) {
        self.init(data: data, identify: nil, columns: columns(), sort: sort)
    }

    /// Creates an unkeyed table sorted through a non-optional binding.
    init(
        _ data: Data,
        sort: Binding<TableSort>,
        @TableColumnBuilder<Row> columns: () -> [TableColumn<Row>]
    ) {
        self.init(data: data, identify: nil, columns: columns(), sort: sort.optionalSort)
    }

    /// Creates a keyed table.
    ///
    /// Cell state follows its row through insertion, removal, and reordering — a
    /// sort included.
    init<ID: ViewIdentifiable>(
        _ data: Data,
        id: @escaping (Row) -> ID,
        sort: Binding<TableSort?>? = nil,
        @TableColumnBuilder<Row> columns: () -> [TableColumn<Row>]
    ) {
        self.init(data: data, identify: { id($0).viewIdentityToken }, columns: columns(), sort: sort)
    }

    /// Creates a keyed table sorted through a non-optional binding.
    init<ID: ViewIdentifiable>(
        _ data: Data,
        id: @escaping (Row) -> ID,
        sort: Binding<TableSort>,
        @TableColumnBuilder<Row> columns: () -> [TableColumn<Row>]
    ) {
        self.init(
            data: data,
            identify: { id($0).viewIdentityToken },
            columns: columns(),
            sort: sort.optionalSort
        )
    }
}

public extension Table where Data.Element: Identifiable, Data.Element.ID: ViewIdentifiable {
    /// Creates a table keyed by each row's own identity.
    init(
        _ data: Data,
        sort: Binding<TableSort?>? = nil,
        @TableColumnBuilder<Row> columns: () -> [TableColumn<Row>]
    ) {
        self.init(data, id: { $0.id }, sort: sort, columns: columns)
    }

    /// Creates a table keyed by each row's own identity, sorted through a
    /// non-optional binding.
    init(
        _ data: Data,
        sort: Binding<TableSort>,
        @TableColumnBuilder<Row> columns: () -> [TableColumn<Row>]
    ) {
        self.init(data, id: { $0.id }, sort: sort.optionalSort, columns: columns)
    }
}

// MARK: - Table modifiers

public extension Table {
    /// Paints a row's background from the row itself.
    ///
    /// This is the one piece of row presentation a cell cannot express, because a
    /// cell only covers its own column. Returning `nil` leaves the row unpainted.
    func rowBackground(_ background: @escaping (Row) -> Background?) -> Table {
        var table = self
        table.rowBackground = background
        return table
    }

    /// Hides the header row.
    func headerHidden(_ hidden: Bool = true) -> Table {
        var table = self
        table.showsHeader = !hidden
        return table
    }

    /// Sizes the columns this way rather than the way the declared widths imply.
    ///
    /// Use ``TableColumnLayout/sizedToContent`` on a table whose columns declare
    /// widths but should still grow for their content, and
    /// ``TableColumnLayout/fixed`` on one that declares none but should share its
    /// width out evenly.
    func columnLayout(_ layout: TableColumnLayout) -> Table {
        var table = self
        table.columnLayout = layout
        return table
    }

    /// Keeps the header in place while the rows scroll under it.
    ///
    /// The header sticks to the top of the nearest scrolling ancestor, so this only
    /// shows when the table is inside one.
    func stickyHeader(_ enabled: Bool = true) -> Table {
        var table = self
        table.headerIsSticky = enabled
        return table
    }
}

private extension Binding where Value == TableSort {
    /// The same storage seen as optional, for the tables whose sort is never absent.
    ///
    /// A write of `nil` cannot reach it — nothing a table does produces one — so
    /// clearing the sort stays a thing only the application can do.
    var optionalSort: Binding<TableSort?> {
        Binding<TableSort?>(
            get: { wrappedValue },
            set: { newValue in
                guard let newValue else { return }
                wrappedValue = newValue
            },
            stateIdentity: stateIdentity
        )
    }
}
