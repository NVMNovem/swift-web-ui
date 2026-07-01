//
//  Alignment.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

/// Alignment intent used by stack layout containers.
public enum Alignment: String, Sendable {
    
    case leading
    case center
    case trailing
    case top
    case bottom

    var cssValue: String {
        switch self {
        case .leading: "flex-start"
        case .center: "center"
        case .trailing: "flex-end"
        case .top: "flex-start"
        case .bottom: "flex-end"
        }
    }
}
