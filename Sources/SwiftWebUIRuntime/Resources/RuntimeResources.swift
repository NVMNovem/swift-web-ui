//
//  RuntimeResources.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 22/07/2026.
//

/// Browser-facing resources owned by a mounted runtime application.
///
/// Resources describe browser intent only. Application build tooling remains
/// responsible for copying referenced files into deployable output.
public struct RuntimeResources: Sendable, Equatable {
    /// Stylesheets installed before the initial view tree is mounted.
    public var stylesheets: [RuntimeStylesheet]

    public init(stylesheets: [RuntimeStylesheet] = []) {
        self.stylesheets = stylesheets
    }
}
