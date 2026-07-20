//
//  StyleRegistry.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import SwiftCSS

struct StyleRegistry {
    private struct StoredRule {
        let className: String
        let declarations: [SwiftCSS.CSSDeclaration]
    }

    private var rules: [StoredRule] = []
    private var classNamesByDeclarations: [String: String] = [:]

    mutating func className(
        for declarations: [SwiftCSS.CSSDeclaration],
        scope _: ResourceScope = .global
    ) -> String {
        let canonical = declarations.map(canonicalDeclaration).joined()
        if let className = classNamesByDeclarations[canonical] {
            return className
        }

        let className = "swui-\(stableHashHex(for: canonical))"
        classNamesByDeclarations[canonical] = className
        rules.append(.init(className: className, declarations: declarations))
        return className
    }

    func renderCSS(prettyPrinted: Bool = true) -> String {
        let nodes = rules.map { rule in
            SwiftCSS.CSSNode.rule(
                .init(
                    selector: .init(
                        selectors: [
                            .init(
                                head: .init(selectors: [.class(rule.className)]),
                                tail: []
                            )
                        ]
                    ),
                    declarations: rule.declarations
                )
            )
        }
        return SwiftCSS.CSSStringRenderer(
            options: .init(prettyPrinted: prettyPrinted)
        ).render(.stylesheet(.init(children: nodes)))
    }

    private func canonicalDeclaration(_ declaration: SwiftCSS.CSSDeclaration) -> String {
        switch declaration {
        case .property(let node):
            "\(node.property):\(node.value);"
        case .raw(let node):
            "\(node.property):\(node.value);"
        }
    }

    private func stableHashHex(for string: String) -> String {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }
        let hex = String(hash, radix: 16)
        return String(repeating: "0", count: max(0, 16 - hex.count)) + hex
    }
}
