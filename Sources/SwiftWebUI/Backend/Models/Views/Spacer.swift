//
//  Spacer.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public struct Spacer: View {
    public typealias Body = Never
    public init() {}
    public var body: Never { fatalError("Spacer primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .spacer }
}
