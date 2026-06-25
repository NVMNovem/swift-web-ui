//
//  StyleRegistry.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftCSS

struct StyleRegistry {
    
    private struct Rule {
        var className: String
        var declarations: [String]
    }

    private var rules: [Rule] = []
    private var classNamesByKey: [String: String] = [:]

    mutating func className(for properties: [any CSSProperty], scope: ResourceScope) -> String {
        let declarations = renderedDeclarations(for: properties)
        let key = "\(scope.key)|\(declarations.joined(separator: "|"))"

        if let className = classNamesByKey[key] {
            return className
        }

        let className = "swui-\(rules.count + 1)"
        classNamesByKey[key] = className
        rules.append(Rule(className: className, declarations: declarations))
        return className
    }

    func renderCSS(prettyPrinted: Bool = true) -> String {
        guard !rules.isEmpty else {
            return ""
        }

        if prettyPrinted {
            return rules
                .map { rule in
                    let declarations = rule.declarations
                        .map { "    \($0)" }
                        .joined(separator: "\n")
                    return ".\(rule.className) {\n\(declarations)\n}"
                }
                .joined(separator: "\n\n")
        }

        return rules
            .map { ".\($0.className) { \($0.declarations.joined(separator: " ")) }" }
            .joined(separator: "")
    }

    private func renderedDeclarations(for properties: [any CSSProperty]) -> [String] {
        properties.map { $0.render(options: CSSRenderOptions(prettyPrinted: true)) }
    }
}

private extension ResourceScope {
    var key: String {
        switch self {
        case .global:
            "global"
        case .component(let name):
            "component:\(name)"
        case .page(let name):
            "page:\(name)"
        }
    }
}
