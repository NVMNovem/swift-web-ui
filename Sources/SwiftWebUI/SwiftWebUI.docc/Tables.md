# Tables

Show rows of data as columns, with a default look and application-owned sorting.

## Overview

``Table`` takes the rows as they are held and a description of the columns. It
lowers to a real `table`, `thead`, and `tbody` tree, so rows and columns are
announced as such and the sorted column is announced with them.

```swift
Table(products, id: { $0.id.uuidString }) {
    TableColumn("Name", value: { $0.name })
    TableColumn("Price", width: .px(96), alignment: .trailing) { product in
        Text(product.formattedPrice)
    }
}
```

A column either shows plain text it also sorts by, or builds whatever view its
cell needs — an editable field, a switch, a button opening an inspector.

## Sorting

Sorting is state the application owns: pass a ``TableSort`` binding, and every
column that declares something to sort by becomes a header button. Clicking one
sorts by it ascending; clicking the column already sorted by turns it round. The
table reads the binding while it lowers and orders the rows itself, so nothing
else has to keep a sorted copy.

```swift
struct ProductsTable: View {
    @State private var sort = TableSort("Name")
    let products: [Product]

    var body: some View {
        Table(products, id: { $0.id.uuidString }, sort: $sort) {
            TableColumn("Name", value: { $0.name })

            // Sorted on the amount behind the cell, not the text in it.
            TableColumn("Price", width: .px(96), alignment: .trailing, value: { $0.cents }) { product in
                Text(product.formattedPrice)
            }

            // An order no single value expresses: missing sorts last.
            TableColumn("Section", width: .px(160), sortBy: { ($0.section ?? "\u{FFFF}") < ($1.section ?? "\u{FFFF}") }) { product in
                Text(product.section ?? "—")
            }

            // Nothing to sort by, so no button: a column of controls.
            TableColumn("On sale", width: .px(80)) { product in
                Switch(isOn: product.isAvailable) { isOn in store.setAvailable(product, isOn) }
            }
        }
    }
}
```

The sort is an ordinary value, so it can be persisted, restored, or set from
elsewhere — a saved view, a deep link, a "sort by price" button beside the table.
A table given no binding sorts nothing and shows no header buttons; the rows
appear in the order they were handed over.

When a sort lives outside `@State` — in a store, say — wrap it in a binding that
also asks for the redraw that store would normally ask for:

```swift
Table(rows, id: { $0.id }, sort: Binding(
    get: { store.sort },
    set: { store.sort = $0; Redraw.request() }
)) { ... }
```

Column identifiers have to be unique within one table: a ``TableSort`` names a
column, and two columns answering to the same name make the sort ambiguous. The
default identifier is the column title, so only same-titled columns need an
explicit `id:`.

A statically rendered document has nothing to run a header button, so it shows the
rows in the order they were handed over, sorted or not. Sorting is a runtime
feature, like every other closure action.

## Customizing the look

A table arrives wearing a plain default look, and every part of it is an ordinary
element declaration rather than a stylesheet rule, so an application modifier
overrides it. Modifiers land on the `table` element itself:

```swift
Div {
    Table(rows, id: { $0.id }, sort: $sort) { ... }
        .stickyHeader()
        .minWidth(.px(1080))
        .font(.system(size: 13))
        .rowBackground { selection.contains($0.id) ? Background(Color("var(--accent-soft)")) : nil }
}
.overflow(.auto)
```

- Column width and alignment belong to ``TableColumn``, because they describe one
  column rather than the table.
- ``Table/rowBackground(_:)`` paints a row from the row itself. It is the one piece
  of row presentation a cell cannot express, since a cell only covers its column.
- ``Table/stickyHeader(_:)`` keeps the header in place while rows scroll under it.
  It sticks to the nearest scrolling ancestor, so the table needs to be inside one.
- ``Table/headerHidden(_:)`` drops the header row.
- Horizontal scrolling is ordinary layout: a `minWidth` on the table and a
  container that scrolls.

Two colours are read from custom properties, so a theme can set them once
instead of restyling every cell: `--swiftwebui-table-border` and
`--swiftwebui-table-header-background`.

For the rules an inline declaration cannot express — a hover state, a striped row,
a print variant — the generated markup carries named classes:
`swiftwebui-table`, `swiftwebui-table-header`, `swiftwebui-table-header-cell`,
`swiftwebui-table-sort`, `swiftwebui-table-sort-indicator`,
`swiftwebui-table-row`, and `swiftwebui-table-cell`. Those rules belong to the
application stylesheet; SwiftWebUI declares none of them itself.

## Row identity

Give the table an `id:` — or rows that are `Identifiable` — when cells own state.
Cell state then follows its row through insertion, removal, and reordering, a
sort included. An unkeyed table identifies rows by position, so a sort moves
state between rows.

## Topics

### Tables

- ``Table``
- ``TableColumn``
- ``TableColumnBuilder``
- ``TableSort``
- ``TableSortOrder``
