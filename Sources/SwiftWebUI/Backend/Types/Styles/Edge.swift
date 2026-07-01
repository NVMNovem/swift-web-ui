//
//  Edge.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

/// Edge set used by spacing modifiers such as padding and margin.
public struct Edge: OptionSet, Sendable {
    public typealias Set = Edge

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let top = Edge(rawValue: 1 << 0)
    public static let leading = Edge(rawValue: 1 << 1)
    public static let bottom = Edge(rawValue: 1 << 2)
    public static let trailing = Edge(rawValue: 1 << 3)
    public static let horizontal: Edge = [.leading, .trailing]
    public static let vertical: Edge = [.top, .bottom]
    public static let all: Edge = [.top, .leading, .bottom, .trailing]
}
