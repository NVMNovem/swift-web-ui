//
//  ViewBuilder.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

@resultBuilder
public enum ViewBuilder {
    public static func buildExpression<V: View>(_ expression: V) -> AnyView {
        AnyView(expression)
    }

    public static func buildExpression<V: View>(_ expressions: [V]) -> AnyView {
        AnyView(GroupView(expressions.map { AnyView($0) }))
    }

    public static func buildExpression(_ expressions: [AnyView]) -> AnyView {
        AnyView(GroupView(expressions))
    }

    public static func buildBlock() -> AnyView {
        AnyView(EmptyView())
    }

    public static func buildBlock(_ component: AnyView) -> AnyView {
        component
    }

    public static func buildBlock(_ components: AnyView...) -> AnyView {
        AnyView(GroupView(components))
    }

    public static func buildOptional(_ component: AnyView?) -> AnyView {
        component ?? AnyView(EmptyView())
    }

    public static func buildEither(first component: AnyView) -> AnyView {
        component
    }

    public static func buildEither(second component: AnyView) -> AnyView {
        component
    }

    public static func buildArray(_ components: [AnyView]) -> AnyView {
        AnyView(GroupView(components))
    }
}
