//
//  TableColumnBuilder.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 16/09/2026.
//

/// Collects the columns of a ``Table``.
///
/// Columns are a homogeneous list rather than a view tree, so this builds an array
/// directly instead of preserving concrete carriers the way ``ViewBuilder`` does.
@resultBuilder
public enum TableColumnBuilder<Row> {
    public static func buildExpression(_ expression: TableColumn<Row>) -> [TableColumn<Row>] { [expression] }
    public static func buildExpression(_ expressions: [TableColumn<Row>]) -> [TableColumn<Row>] { expressions }
    public static func buildBlock() -> [TableColumn<Row>] { [] }
    public static func buildBlock(_ components: [TableColumn<Row>]...) -> [TableColumn<Row>] { components.flatMap { $0 } }
    public static func buildOptional(_ component: [TableColumn<Row>]?) -> [TableColumn<Row>] { component ?? [] }
    public static func buildEither(first component: [TableColumn<Row>]) -> [TableColumn<Row>] { component }
    public static func buildEither(second component: [TableColumn<Row>]) -> [TableColumn<Row>] { component }
    public static func buildArray(_ components: [[TableColumn<Row>]]) -> [TableColumn<Row>] { components.flatMap { $0 } }
}
