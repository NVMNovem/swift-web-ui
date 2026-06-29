//
//  StyleRegistry.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

import Foundation
import SwiftCSS

struct StyleRegistry {
    
    private struct Rule {
        var className: String
        var declarations: [String]
    }

    private var rules: [Rule] = []
    private var classNamesByCanonicalDeclarations: [String: String] = [:]

    mutating func className(for properties: [any CSSProperty], scope _: ResourceScope) -> String {
        let declarations = renderedDeclarations(for: properties)
        let canonicalDeclarations = canonicalDeclarationString(for: declarations)

        if let className = classNamesByCanonicalDeclarations[canonicalDeclarations] {
            return className
        }

        let className = "swui-\(stableHashHex(for: canonicalDeclarations))"
        classNamesByCanonicalDeclarations[canonicalDeclarations] = className
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

    private func canonicalDeclarationString(for declarations: [String]) -> String {
        declarations
            .map { declaration in
                let trimmed = declaration.trimmingCharacters(in: .whitespacesAndNewlines)
                guard let separator = trimmed.firstIndex(of: ":") else {
                    return trimmed
                }

                let property = trimmed[..<separator].trimmingCharacters(in: .whitespacesAndNewlines)
                let valueStart = trimmed.index(after: separator)
                let value = trimmed[valueStart...].trimmingCharacters(in: .whitespacesAndNewlines)
                return "\(property):\(value)"
            }
            .joined()
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

private extension Substring {
    func trimmingCharacters(in set: CharacterSet) -> String {
        String(self).trimmingCharacters(in: set)
    }
}
