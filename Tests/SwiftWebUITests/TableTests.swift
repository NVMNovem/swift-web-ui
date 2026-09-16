//
//  TableTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 16/09/2026.
//

import Testing
@_spi(Rendering) import SwiftWebUI
import SwiftWebUIStatic

private struct Product: Equatable {
    let id: String
    let name: String
    let cents: Int
}

private let products = [
    Product(id: "b", name: "Frikandel", cents: 320),
    Product(id: "a", name: "Bicky", cents: 480),
    Product(id: "c", name: "Curryworst", cents: 250),
]

private func sortBinding(_ storage: SortBox) -> Binding<TableSort?> {
    Binding(get: { storage.value }, set: { storage.value = $0 })
}

private final class SortBox {
    var value: TableSort?
    init(_ value: TableSort?) { self.value = value }
}

private func productTable(sort: Binding<TableSort?>? = nil) -> Table<[Product]> {
    Table(products, id: { $0.id }, sort: sort) {
        TableColumn("Name", value: { $0.name }) { product in
            Text(product.name)
        }
        TableColumn("Price", width: .px(96), alignment: .trailing, value: { $0.cents }) { product in
            Text("\(product.cents)")
        }
        TableColumn("Actions") { product in
            Button("Edit \(product.name)") {}
        }
    }
}

// MARK: - Structure

@Test func tableLowersToTableHeadAndBodyElements() {
    let table = requireTableElement(productTable())
    #expect(table?.tagName == "table")
    #expect(table?.attributes.contains { $0.name == "class" && $0.value == "swiftwebui-table" } == true)
    #expect(table?.styles.contains { $0.name == "border-collapse" && $0.value == "collapse" } == true)

    let sections = table?.children.compactMap { elementTagName($0) } ?? []
    #expect(sections == ["thead", "tbody"])

    let headerCells = children(of: firstChild(of: table?.children.first))
    #expect(headerCells.count == 3)
    #expect(headerCells.allSatisfy { $0.tagName == "th" })
    #expect(headerCells.allSatisfy { cell in cell.attributes.contains { $0.name == "scope" && $0.value == "col" } })

    let bodyRows = children(of: table?.children.last)
    #expect(bodyRows.count == 3)
    #expect(bodyRows.allSatisfy { $0.tagName == "tr" })
    #expect(children(of: bodyRows.first.map { WebNode.element($0) }).allSatisfy { $0.tagName == "td" })
}

@Test func tableColumnWidthAndAlignmentLandOnTheirOwnCells() {
    let table = requireTableElement(productTable())
    let headerCells = children(of: firstChild(of: table?.children.first))
    let priceHeader = headerCells[1]
    #expect(priceHeader.styles.contains { $0.name == "width" && $0.value == "96px" })
    #expect(priceHeader.styles.contains { $0.name == "text-align" && $0.value == "right" })

    let firstRowCells = children(of: table?.children.last.flatMap { firstChild(of: $0) })
    #expect(firstRowCells[1].styles.contains { $0.name == "text-align" && $0.value == "right" })
    #expect(firstRowCells[0].styles.contains { $0.name == "text-align" && $0.value == "left" })
}

@Test func tableModifiersOverrideTheDefaultLook() {
    let table = requireTableElement(ViewNodeToWebNodeLowerer().lower(
        productTable()
            .minWidth(.px(980))
            .width(.px(1200))
            .class("catalogue-table")
            .makeViewNode()
    ))
    #expect(table?.styles.contains { $0.name == "min-width" && $0.value == "980px" } == true)
    // The default `width: 100%` is declared first, so the modifier's value is the
    // one that survives normalization.
    #expect(table?.styles.filter { $0.name == "width" }.map { $0.value } == ["1200px"])
    #expect(table?.attributes.contains { $0.name == "class" && $0.value == "swiftwebui-table catalogue-table" } == true)
}

@Test func declaredColumnWidthsHoldAndAreOtherwiseLeftToTheContent() {
    // This table declares widths, so they are what the columns are.
    let declared = requireTableElement(productTable())
    #expect(declared?.styles.contains { $0.name == "table-layout" && $0.value == "fixed" } == true)

    // This one declares none, so nothing has been said about width.
    let undeclared = requireTableElement(
        Table(products, id: { $0.id }) {
            TableColumn("Name", value: { $0.name })
            TableColumn("Price", value: { $0.cents }) { Text("\($0.cents)") }
        }
    )
    #expect(undeclared?.styles.contains { $0.name == "table-layout" && $0.value == "auto" } == true)
}

@Test func columnLayoutOverridesWhatTheWidthsImply() {
    let sizedToContent = requireTableElement(productTable().columnLayout(.sizedToContent))
    #expect(sizedToContent?.styles.contains { $0.name == "table-layout" && $0.value == "auto" } == true)

    let fixed = requireTableElement(
        Table(products, id: { $0.id }) {
            TableColumn("Name", value: { $0.name })
        }
        .columnLayout(.fixed)
    )
    #expect(fixed?.styles.contains { $0.name == "table-layout" && $0.value == "fixed" } == true)
}

// MARK: - Sorting

@Test func sortableColumnsBecomeHeaderButtonsAndOthersStayText() {
    let box = SortBox(TableSort("Name"))
    let table = requireTableElement(productTable(sort: sortBinding(box)))
    let headerCells = children(of: firstChild(of: table?.children.first))

    let nameButton = children(of: headerCells.first.map { WebNode.element($0) }).first
    #expect(nameButton?.tagName == "button")
    #expect(nameButton?.attributes.contains { $0.name == "type" && $0.value == "button" } == true)
    #expect(headerCells[0].attributes.contains { $0.name == "aria-sort" && $0.value == "ascending" })

    // A browser styles its own form controls, so a header button says in as many
    // words that it wears whatever the header cell wears.
    let inherited = ["font", "color", "text-transform", "letter-spacing"]
    #expect(inherited.allSatisfy { name in
        nameButton?.styles.contains { $0.name == name && $0.value == "inherit" } == true
    })
    #expect(headerCells[1].attributes.contains { $0.name == "aria-sort" && $0.value == "none" })

    // A column with no comparator gets no control at all rather than a dead one.
    #expect(headerCells[2].attributes.allSatisfy { $0.name != "aria-sort" })
    #expect(children(of: headerCells[2]).isEmpty)
}

@Test func tableWithoutASortBindingHasNoHeaderButtons() {
    let table = requireTableElement(productTable())
    let headerCells = children(of: firstChild(of: table?.children.first))
    #expect(headerCells.allSatisfy { children(of: $0).isEmpty })
    #expect(headerCells.allSatisfy { cell in cell.attributes.allSatisfy { $0.name != "aria-sort" } })
}

@Test func tableOrdersItsRowsByTheActiveColumn() {
    let ascending = requireTableElement(productTable(sort: sortBinding(SortBox(TableSort("Name")))))
    #expect(rowTitles(ascending) == ["Bicky", "Curryworst", "Frikandel"])

    let descending = requireTableElement(
        productTable(sort: sortBinding(SortBox(TableSort("Name", order: .descending))))
    )
    #expect(rowTitles(descending) == ["Frikandel", "Curryworst", "Bicky"])

    // The column sorts on the amount behind the cell, not on the text in it.
    let byPrice = requireTableElement(productTable(sort: sortBinding(SortBox(TableSort("Price")))))
    #expect(rowTitles(byPrice) == ["Curryworst", "Frikandel", "Bicky"])

    // An unsorted table keeps the order it was handed.
    let unsorted = requireTableElement(productTable(sort: sortBinding(SortBox(nil))))
    #expect(rowTitles(unsorted) == ["Frikandel", "Bicky", "Curryworst"])
}

@Test func clickingAHeaderWritesTheNextSortThroughTheBinding() {
    let box = SortBox(TableSort("Name"))
    let table = requireTableElement(productTable(sort: sortBinding(box)))
    let headerCells = children(of: firstChild(of: table?.children.first))

    // The active column turns round.
    runAction(of: children(of: headerCells[0]).first)
    #expect(box.value == TableSort("Name", order: .descending))

    // Another column starts ascending, whichever way the previous one ran.
    runAction(of: children(of: headerCells[1]).first)
    #expect(box.value == TableSort("Price", order: .ascending))
}

@Test func theActiveColumnCarriesASortIndicator() {
    let ascending = requireTableElement(productTable(sort: sortBinding(SortBox(TableSort("Name")))))
    #expect(indicatorText(ascending, column: 0) == "\u{25B2}")
    #expect(indicatorText(ascending, column: 1) == nil)

    let descending = requireTableElement(
        productTable(sort: sortBinding(SortBox(TableSort("Name", order: .descending))))
    )
    #expect(indicatorText(descending, column: 0) == "\u{25BC}")
}

// MARK: - Row and header presentation

@Test func rowBackgroundPaintsTheRowItself() {
    let table = requireTableElement(
        productTable().rowBackground { $0.id == "a" ? Background("#eef") : nil }
    )
    let rows = children(of: table?.children.last)
    #expect(rows[1].styles.contains { $0.name == "background" && $0.value == "#eef" })
    #expect(rows[0].styles.isEmpty)
}

@Test func headerCanBeHiddenAndMadeSticky() {
    let hidden = requireTableElement(productTable().headerHidden())
    #expect(hidden?.children.compactMap { elementTagName($0) } == ["tbody"])

    let sticky = requireTableElement(productTable().stickyHeader())
    let headerCells = children(of: firstChild(of: sticky?.children.first))
    #expect(headerCells.allSatisfy { cell in
        cell.styles.contains { $0.name == "position" && $0.value == "sticky" }
            && cell.styles.contains { $0.name == "top" && $0.value == "0" }
    })
}

// MARK: - Static rendering

@Test func tableRendersAsMarkupAStaticDocumentCanServe() {
    let rendered = HTMLRenderer().renderView(
        Table([products[0]], id: { $0.id }) {
            TableColumn("Name", value: { $0.name })
        }
    )
    let html = rendered.content.htmlString()
    #expect(html.contains("<table"))
    #expect(html.contains("<th"))
    #expect(html.contains("scope=\"col\""))
    #expect(html.contains("Frikandel"))
}

/// The shape the hand-built product tables in applications actually have: a
/// leading control column, sortable text, an amount sorted on the number behind
/// it, a column of controls that sorts on nothing, a selected-row background, and
/// a header that stays put over a table wider than its container.
@Test func tableCoversAHandBuiltProductListing() {
    let box = SortBox(TableSort("price"))
    let selected: Set<String> = ["a"]

    let node = Table(products, id: { $0.id }, sort: sortBinding(box)) {
        TableColumn("", id: "selection", width: .px(18)) { product in
            Button(action: {}) { Text(selected.contains(product.id) ? "x" : "") }
        }
        TableColumn("Product", id: "name", value: { $0.name }) { product in
            VStack(alignment: .leading) {
                Text(product.name)
                Text(product.id)
            }
        }
        TableColumn("Price", id: "price", width: .px(96), alignment: .trailing, value: { $0.cents }) { product in
            Text("\(product.cents)")
        }
        TableColumn("On sale", id: "availability", width: .px(80)) { product in
            Button("Toggle \(product.name)") {}
        }
    }
    .rowBackground { selected.contains($0.id) ? Background("#eef") : nil }
    .stickyHeader()
    .minWidth(.px(980))
    .makeViewNode()

    let table = requireTableElement(ViewNodeToWebNodeLowerer().lower(node))
    #expect(table?.styles.contains { $0.name == "min-width" && $0.value == "980px" } == true)
    // The tick is in the selected row, which the price sort puts last.
    #expect(rowTitles(table) == ["", "", "x"])

    let headerCells = children(of: firstChild(of: table?.children.first))
    #expect(headerCells.count == 4)
    // Only the two columns with something to sort by are buttons.
    #expect(headerCells.map { children(of: $0).first?.tagName } == [nil, "button", "button", nil])
    #expect(headerCells[2].attributes.contains { $0.name == "aria-sort" && $0.value == "ascending" })

    // Sorted by the amount: the cheapest row is first, and it is not the selected one.
    let rows = children(of: table?.children.last)
    #expect(rows.first?.styles.isEmpty == true)
    #expect(rows.contains { $0.styles.contains { $0.name == "background" && $0.value == "#eef" } })
    #expect(secondCellTexts(table) == ["Curryworst", "Frikandel", "Bicky"])
}

// MARK: - Helpers

private func requireTableElement<Data: Sequence>(_ table: Table<Data>) -> WebElementNode? {
    requireTableElement(ViewNodeToWebNodeLowerer().lower(table.makeViewNode()))
}

private func requireTableElement(_ node: WebNode) -> WebElementNode? {
    guard case .element(let element) = node else {
        Issue.record("Expected a table element")
        return nil
    }
    return element
}

private func elementTagName(_ node: WebNode) -> String? {
    guard case .element(let element) = node else { return nil }
    return element.tagName
}

private func firstChild(of node: WebNode?) -> WebNode? {
    guard case .element(let element)? = node else { return nil }
    return element.children.first
}

private func children(of node: WebNode?) -> [WebElementNode] {
    guard case .element(let element)? = node else { return [] }
    return element.children.compactMap { child in
        guard case .element(let childElement) = child else { return nil }
        return childElement
    }
}

private func children(of element: WebElementNode) -> [WebElementNode] {
    children(of: WebNode.element(element))
}

/// The text of every first cell, which is the name column in these tables.
private func rowTitles(_ table: WebElementNode?) -> [String] {
    children(of: table?.children.last).compactMap { row in
        guard let cell = children(of: row).first else { return nil }
        return text(in: .element(cell))
    }
}

/// The text of every second cell, which is the name column in the listing table.
private func secondCellTexts(_ table: WebElementNode?) -> [String] {
    children(of: table?.children.last).compactMap { row in
        let cells = children(of: row)
        guard cells.count > 1 else { return nil }
        return text(in: .element(cells[1]))
    }
}

private func indicatorText(_ table: WebElementNode?, column: Int) -> String? {
    let headerCells = children(of: firstChild(of: table?.children.first))
    guard let button = children(of: headerCells[column]).first else { return nil }
    guard let indicator = children(of: button).first(where: { element in
        element.attributes.contains { $0.name == "class" && $0.value == "swiftwebui-table-sort-indicator" }
    }) else { return nil }
    return text(in: .element(indicator))
}

private func text(in node: WebNode) -> String? {
    switch node {
    case .text(let content): content
    case .element(let element): element.children.compactMap(text(in:)).first
    case .fragment(let children): children.compactMap(text(in:)).first
    case .empty: nil
    }
}

private func runAction(of element: WebElementNode?) {
    guard case .closure(let action)? = element?.action else {
        Issue.record("Expected a closure action on the header button")
        return
    }
    action()
}
