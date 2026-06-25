//
//  Edge.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public enum Edge: Sendable {
    
    case top
    case leading
    case bottom
    case trailing
    case horizontal
    case vertical
    case all

    public struct Set: OptionSet, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let top = Set(rawValue: 1 << 0)
        public static let leading = Set(rawValue: 1 << 1)
        public static let bottom = Set(rawValue: 1 << 2)
        public static let trailing = Set(rawValue: 1 << 3)
        public static let horizontal: Set = [.leading, .trailing]
        public static let vertical: Set = [.top, .bottom]
        public static let all: Set = [.top, .leading, .bottom, .trailing]
    }
}
