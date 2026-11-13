//
//  RuntimeStylesheetInstaller.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 22/07/2026.
//

struct RuntimeStylesheetInstaller<Backend: BrowserHeadBackend> {
    let backend: Backend

    func install(
        _ resources: RuntimeResources
    ) throws(BrowserHeadBackendError) -> InstalledRuntimeResources<Backend.Node> {
        guard !resources.stylesheets.isEmpty else {
            return InstalledRuntimeResources()
        }

        let head = try backend.documentHead()
        var handles: [Backend.Node] = []
        handles.reserveCapacity(resources.stylesheets.count)

        do {
            for stylesheet in resources.stylesheets {
                let handle = try element(for: stylesheet)
                backend.append(handle, to: head)
                handles.append(handle)
            }
        } catch {
            for handle in handles.reversed() {
                backend.remove(handle, from: head)
            }
            throw error
        }

        return InstalledRuntimeResources(stylesheetHandles: handles)
    }

    /// The `link` or `style` element for one stylesheet, not yet in the head.
    func element(for stylesheet: RuntimeStylesheet) throws(BrowserHeadBackendError) -> Backend.Node {
        switch stylesheet {
        case .external(let href):
            let handle = backend.createElement("link")
            backend.setAttribute(name: "rel", value: "stylesheet", on: handle)
            backend.setAttribute(name: "href", value: href, on: handle)
            return handle
        case .inline(let css):
            let handle = backend.createElement("style")
            try backend.setResourceText(css, on: handle)
            return handle
        }
    }
}
