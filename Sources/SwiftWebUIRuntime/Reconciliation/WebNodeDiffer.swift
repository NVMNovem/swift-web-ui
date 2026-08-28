//
//  WebNodeDiffer.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

@_spi(Rendering) import SwiftWebUI

/// Produces deterministic, positional DOM mutations for two renderer-neutral trees.
struct WebNodeDiffer {
    func diff(old: WebNode, new: WebNode) -> [DOMPatch] {
        var patches: [DOMPatch] = []
        diff(old: old, new: new, path: NodePath(), into: &patches)
        return patches
    }

    private func diff(
        old: WebNode,
        new: WebNode,
        path: NodePath,
        into patches: inout [DOMPatch]
    ) {
        switch (old, new) {
        case (.empty, .empty):
            return
        case (.text(let oldValue), .text(let newValue)):
            if oldValue != newValue {
                patches.append(.setText(path: path, value: newValue))
            }
        case (.element(let oldElement), .element(let newElement)):
            guard oldElement.tagName == newElement.tagName else {
                patches.append(.replaceNode(path: path, node: new))
                return
            }
            diffNamedValues(
                old: oldElement.attributes,
                new: newElement.attributes,
                name: { $0.name },
                value: { $0.value },
                remove: { .removeAttribute(path: path, name: $0) },
                set: { .setAttribute(path: path, name: $0, value: $1) },
                into: &patches
            )
            diffNamedValues(
                old: oldElement.styles,
                new: newElement.styles,
                name: { $0.name },
                value: { $0.value },
                remove: { .removeStyle(path: path, name: $0) },
                set: { .setStyle(path: path, name: $0, value: $1) },
                into: &patches
            )
            if actionsRequireReplacement(old: oldElement.action, new: newElement.action) {
                patches.append(.replaceAction(path: path, action: newElement.action))
            }
            if keyActionsRequireReplacement(old: oldElement.keyActions, new: newElement.keyActions) {
                patches.append(.replaceKeyActions(path: path, actions: newElement.keyActions))
            }
            if actionsRequireReplacement(old: oldElement.dismissAction, new: newElement.dismissAction) {
                patches.append(.replaceDismissAction(path: path, action: newElement.dismissAction))
            }
            // Presentation is reconciled like any other element state, so the
            // view never calls `showModal()` itself.
            if let presentation = newElement.presentation, presentation != oldElement.presentation {
                patches.append(.setDialogPresentation(path: path, presentation: presentation))
            }
            // Only the transition into asking for focus may move it. An element
            // that already had focus requested keeps it: re-emitting on every
            // rerender would yank focus back mid-typing on unrelated state
            // changes. This has to be explicit — the element comparison above
            // would otherwise treat any difference as a reason to act.
            if !oldElement.requestsFocus, newElement.requestsFocus {
                patches.append(.focus(path: path))
            }
            diffChildren(
                old: oldElement.children,
                new: newElement.children,
                parent: path,
                into: &patches
            )
        case (.fragment(let oldChildren), .fragment(let newChildren)):
            diffChildren(old: oldChildren, new: newChildren, parent: path, into: &patches)
        default:
            patches.append(.replaceNode(path: path, node: new))
        }
    }

    private func diffChildren(
        old: [WebNode],
        new: [WebNode],
        parent: NodePath,
        into patches: inout [DOMPatch]
    ) {
        let sharedCount = min(old.count, new.count)
        for index in 0..<sharedCount {
            diff(old: old[index], new: new[index], path: parent.appending(index), into: &patches)
        }
        if new.count > old.count {
            for index in old.count..<new.count {
                patches.append(.insertChild(parent: parent, index: index, node: new[index]))
            }
        } else if old.count > new.count {
            for index in stride(from: old.count - 1, through: new.count, by: -1) {
                patches.append(.removeChild(parent: parent, index: index))
            }
        }
    }

    private func diffNamedValues<Value>(
        old: [Value],
        new: [Value],
        name: (Value) -> String,
        value: (Value) -> String,
        remove: (String) -> DOMPatch,
        set: (String, String) -> DOMPatch,
        into patches: inout [DOMPatch]
    ) {
        var oldValues: [String: String] = [:]
        var newValues: [String: String] = [:]
        for item in old { oldValues[name(item)] = value(item) }
        for item in new { newValues[name(item)] = value(item) }

        for item in old where newValues[name(item)] == nil {
            patches.append(remove(name(item)))
        }
        for item in new where oldValues[name(item)] != value(item) {
            patches.append(set(name(item), value(item)))
        }
    }

    /// Key handlers replace conservatively for the same reason click actions do:
    /// a closure has no renderer-neutral identity, so a rerender that still
    /// carries one cannot be shown to carry the same one.
    private func keyActionsRequireReplacement(old: [KeyAction], new: [KeyAction]) -> Bool {
        if old.isEmpty, new.isEmpty { return false }
        if old.count != new.count { return true }
        return zip(old, new).contains { pair in
            pair.0.key != pair.1.key
                || actionsRequireReplacement(old: pair.0.action, new: pair.1.action)
        }
    }

    /// Closure actions have no renderer-neutral identity token, so any rerender
    /// of an action-bearing element conservatively replaces its registration.
    private func actionsRequireReplacement(old: ActionIntent?, new: ActionIntent?) -> Bool {
        switch (old, new) {
        case (nil, nil):
            false
        case (.setState(let oldMutation), .setState(let newMutation)):
            oldMutation != newMutation
        default:
            true
        }
    }
}
