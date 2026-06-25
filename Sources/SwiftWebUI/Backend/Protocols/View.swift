//
//  View.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public protocol View {
    associatedtype Body: View

    @ViewBuilder var body: Body { get }
}
