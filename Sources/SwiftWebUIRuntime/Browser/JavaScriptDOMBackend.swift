//
//  JavaScriptDOMBackend.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

#if arch(wasm32)
import JavaScriptKit
@_spi(Rendering) import SwiftWebUI

final class JavaScriptDOMBackend: BrowserHeadBackend {
    typealias Node = JSObject
    typealias ActionRegistration = JSClosure

    /// A pending `setTimeout` or `requestAnimationFrame`.
    ///
    /// The closure is retained alongside the handle so it stays alive until the
    /// browser calls it, and is released whether it fires or is cancelled.
    struct ScheduledWork {
        let handler: JSClosure
        let handle: JSValue
        let isAnimationFrame: Bool
    }

    private let document: JSObject

    init?() {
        guard let document = JSObject.global.document.object else {
            return nil
        }
        self.document = document
    }

    func element(withID identifier: String) -> JSObject? {
        document.getElementById!(identifier).object
    }

    var documentTitle: String {
        document.title.string ?? ""
    }

    func setDocumentTitle(_ title: String) {
        document.title = .string(title)
    }

    func documentHead() throws(BrowserHeadBackendError) -> JSObject {
        guard let head = document.head.object else {
            throw BrowserHeadBackendError.documentHeadUnavailable
        }
        return head
    }

    func documentBody() throws(BrowserHeadBackendError) -> JSObject {
        guard let body = document.body.object else {
            throw BrowserHeadBackendError.documentBodyUnavailable
        }
        return body
    }

    func attributeValue(name: String, on node: JSObject) -> String? {
        node.getAttribute!(name).string
    }

    // Not optimized: Swift 6.3.3 crashes in CopyPropagation ("Found outside of
    // lifetime use") on this function when it compiles Embedded Swift with -O.
    // It runs once per icon change, so nothing is lost.
    @_optimize(none)
    func documentIconLinks() -> [JSObject] {
        guard let matches = document.querySelectorAll?("link[rel~=\"icon\"]").object else {
            return []
        }
        guard let count = matches.length.number.map(Int.init) else { return [] }

        var links: [JSObject] = []
        links.reserveCapacity(count)
        for index in 0..<count {
            if let link = matches[index].object {
                links.append(link)
            }
        }
        return links
    }

    func inlineStyleValue(name: String, on node: JSObject) -> String? {
        guard let value = node.style.object?.getPropertyValue!(name).string, !value.isEmpty else {
            return nil
        }
        return value
    }

    func createElement(_ tagName: String) -> JSObject {
        document.createElement!(tagName).object!
    }

    func createTextNode(_ content: String) -> JSObject {
        document.createTextNode!(content).object!
    }

    func setText(_ content: String, on node: JSObject) {
        node.nodeValue = .string(content)
    }

    func setResourceText(_ content: String, on node: JSObject) throws(BrowserHeadBackendError) {
        node.textContent = .string(content)
    }

    func setAttribute(name: String, value: String, on node: JSObject) {
        _ = node.setAttribute!(name, value)
    }

    func removeAttribute(name: String, from node: JSObject) {
        _ = node.removeAttribute!(name)
    }

    func setStyle(name: String, value: String, on node: JSObject) {
        _ = node.style.object!.setProperty!(name, value)
    }

    func removeStyle(name: String, from node: JSObject) {
        _ = node.style.object!.removeProperty!(name)
    }

    func setClickAction(_ action: @escaping () -> Void, on node: JSObject) -> JSClosure {
        let handler = JSClosure { _ in
            action()
            return .undefined
        }
        node.onclick = .object(handler)
        return handler
    }

    func removeClickAction(from node: JSObject, registration: JSClosure) {
        node.onclick = .null
    }

    func setKeyAction(
        keys: [String],
        action: @escaping (String) -> Void,
        on node: JSObject
    ) -> JSClosure {
        let handler = JSClosure { arguments in
            guard let key = arguments.first?.key.string, keys.contains(key) else {
                return .undefined
            }
            action(key)
            return .undefined
        }
        node.onkeydown = .object(handler)
        return handler
    }

    func removeKeyAction(from node: JSObject, registration: JSClosure) {
        node.onkeydown = .null
    }

    func setDragAction(
        _ representations: @escaping () -> [ItemRepresentation],
        on node: JSObject
    ) -> JSClosure {
        let handler = JSClosure { arguments in
            guard let transfer = arguments.first?.dataTransfer.object else { return .undefined }
            for representation in representations() {
                _ = transfer.setData!(representation.contentType.identifier, representation.value)
            }
            return .undefined
        }
        node.ondragstart = .object(handler)
        return handler
    }

    func removeDragAction(from node: JSObject, registration: JSClosure) {
        node.ondragstart = .null
    }

    func setDropAction(
        _ handler: @escaping (DragEventPhase, DropInfo) -> DropOperation?,
        on node: JSObject
    ) -> JSClosure {
        // One closure serves all four events. It reads the element from
        // `currentTarget` rather than capturing `node`, which would tie the node
        // and its own handler into a cycle neither garbage collector can see.
        let listener = JSClosure { arguments in
            guard
                let event = arguments.first?.object,
                let element = event.currentTarget.object,
                let phase = Self.dragEventPhase(of: event, on: element)
            else {
                return .undefined
            }
            let transfer = event.dataTransfer.object
            let types = transfer.map(Self.transferTypes) ?? []
            let info = DropInfo(
                location: Self.location(of: event, in: element),
                contentTypes: types.compactMap { UTType(mimeType: $0) },
                representations: phase == .drop ? Self.representations(of: types, in: transfer) : nil
            )
            guard let operation = handler(phase, info), operation.acceptsDrop else {
                return .undefined
            }
            _ = event.preventDefault!()
            _ = event.stopPropagation!()
            if phase != .drop {
                transfer?.dropEffect = .string(operation == .move ? "move" : "copy")
            }
            return .undefined
        }
        node.ondragenter = .object(listener)
        node.ondragover = .object(listener)
        node.ondragleave = .object(listener)
        node.ondrop = .object(listener)
        return listener
    }

    func removeDropAction(from node: JSObject, registration: JSClosure) {
        node.ondragenter = .null
        node.ondragover = .null
        node.ondragleave = .null
        node.ondrop = .null
    }

    /// The phase a drag event stands for, or `nil` for a `dragleave` that only
    /// moved between the element's own descendants.
    private static func dragEventPhase(of event: JSObject, on element: JSObject) -> DragEventPhase? {
        switch event.type.string {
        case "dragenter":
            return .enter
        case "dragover":
            return .over
        case "dragleave":
            if let entered = event.relatedTarget.object, element.contains!(entered).boolean == true {
                return nil
            }
            return .leave
        case "drop":
            return .drop
        default:
            return nil
        }
    }

    /// The formats a drag carries. `Files` is listed too, and is not a MIME type.
    private static func transferTypes(of transfer: JSObject) -> [String] {
        guard let types = transfer.types.object, let count = types.length.number.map(Int.init) else {
            return []
        }
        var result: [String] = []
        result.reserveCapacity(count)
        for index in 0..<count {
            if let type = types[index].string {
                result.append(type)
            }
        }
        return result
    }

    private static func representations(of types: [String], in transfer: JSObject?) -> [ItemRepresentation] {
        guard let transfer else { return [] }
        var result: [ItemRepresentation] = []
        for type in types {
            guard let contentType = UTType(mimeType: type), let value = transfer.getData!(type).string else {
                continue
            }
            result.append(.init(contentType: contentType, value: value))
        }
        return result
    }

    /// The pointer's position relative to the element's border box.
    private static func location(of event: JSObject, in element: JSObject) -> Point {
        guard let bounds = element.getBoundingClientRect!().object else { return .zero }
        return Point(
            x: (event.clientX.number ?? 0) - (bounds.left.number ?? 0),
            y: (event.clientY.number ?? 0) - (bounds.top.number ?? 0)
        )
    }

    func presentDialog(_ node: JSObject, modal: Bool) {
        if modal {
            _ = node.showModal!()
        } else {
            _ = node.show!()
        }
    }

    func dismissDialog(_ node: JSObject) {
        _ = node.close!()
    }

    func setDismissAction(_ action: @escaping () -> Void, on node: JSObject) -> JSClosure {
        let handler = JSClosure { _ in
            action()
            return .undefined
        }
        // `close` rather than `cancel`: Escape, the backdrop, and an explicit
        // `close()` all end in `close`, and only `cancel` is preventable.
        node.onclose = .object(handler)
        return handler
    }

    func removeDismissAction(from node: JSObject, registration: JSClosure) {
        node.onclose = .null
    }

    func append(_ child: JSObject, to parent: JSObject) {
        _ = parent.appendChild!(child)
    }

    func insert(_ child: JSObject, into parent: JSObject, before reference: JSObject?) {
        if let reference {
            _ = parent.insertBefore!(child, reference)
        } else {
            _ = parent.appendChild!(child)
        }
    }

    func remove(_ child: JSObject, from parent: JSObject) {
        _ = parent.removeChild!(child)
    }

    func removeAllChildren(from parent: JSObject) {
        _ = parent.replaceChildren!()
    }

    func focus(_ node: JSObject) {
        _ = node.focus!()
    }

    func onNextAnimationFrame(_ body: @escaping () -> Void) -> ScheduledWork {
        let handler = JSClosure { _ in
            body()
            return .undefined
        }
        let handle = JSObject.global.requestAnimationFrame.function!(handler)
        return ScheduledWork(handler: handler, handle: handle, isAnimationFrame: true)
    }

    func schedule(afterMilliseconds milliseconds: Int, _ body: @escaping () -> Void) -> ScheduledWork {
        let handler = JSClosure { _ in
            body()
            return .undefined
        }
        let handle = JSObject.global.setTimeout.function!(handler, milliseconds)
        return ScheduledWork(handler: handler, handle: handle, isAnimationFrame: false)
    }

    func cancel(_ work: ScheduledWork) {
        if work.isAnimationFrame {
            _ = JSObject.global.cancelAnimationFrame.function!(work.handle)
        } else {
            _ = JSObject.global.clearTimeout.function!(work.handle)
        }
    }

    func prefersReducedMotion() -> Bool {
        guard let matchMedia = JSObject.global.matchMedia.function else { return false }
        return matchMedia("(prefers-reduced-motion: reduce)").object?.matches.boolean ?? false
    }
}
#endif
