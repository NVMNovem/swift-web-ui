//
//  InstalledRuntimeResources.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 22/07/2026.
//

final class InstalledRuntimeResources<Handle> {
    private(set) var stylesheetHandles: [Handle]

    init(stylesheetHandles: [Handle] = []) {
        self.stylesheetHandles = stylesheetHandles
    }
}
