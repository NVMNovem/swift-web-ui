//
//  TabBuilder.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 25/06/2026.
//

/// Builds the tab arrays consumed by ``TabBar`` and ``TabView``.
@resultBuilder
public enum TabBuilder<Value: Hashable> {
    public static func buildExpression(_ expression: Tab<Value>) -> [Tab<Value>] {
        [expression]
    }

    public static func buildExpression(_ expressions: [Tab<Value>]) -> [Tab<Value>] {
        expressions
    }

    public static func buildBlock() -> [Tab<Value>] {
        []
    }

    public static func buildBlock(_ components: [Tab<Value>]...) -> [Tab<Value>] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [Tab<Value>]?) -> [Tab<Value>] {
        component ?? []
    }

    public static func buildEither(first component: [Tab<Value>]) -> [Tab<Value>] {
        component
    }

    public static func buildEither(second component: [Tab<Value>]) -> [Tab<Value>] {
        component
    }

    public static func buildArray(_ components: [[Tab<Value>]]) -> [Tab<Value>] {
        components.flatMap { $0 }
    }
}
