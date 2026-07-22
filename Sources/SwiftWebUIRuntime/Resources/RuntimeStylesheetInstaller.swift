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
    ) throws -> InstalledRuntimeResources<Backend.Node> {
        guard !resources.stylesheets.isEmpty else {
            return InstalledRuntimeResources()
        }

        let head = try backend.documentHead()
        var handles: [Backend.Node] = []
        handles.reserveCapacity(resources.stylesheets.count)

        do {
            for stylesheet in resources.stylesheets {
                let handle: Backend.Node
                switch stylesheet {
                case .external(let href):
                    handle = backend.createElement("link")
                    backend.setAttribute(name: "rel", value: "stylesheet", on: handle)
                    backend.setAttribute(name: "href", value: href, on: handle)
                case .inline(let css):
                    handle = backend.createElement("style")
                    try backend.setResourceText(css, on: handle)
                }
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
}
