//
//  TransitionPhases.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 28/08/2026.
//

/// The classes an element wears while it is arriving and while it is leaving.
///
/// `enter` and `exit` are application class names. SwiftWebUI schedules them; the
/// rules behind them belong to an application stylesheet, like every other named
/// selector.
///
/// `durationMilliseconds` is a number rather than a CSS string because the
/// runtime has to schedule against it: it holds a leaving element in the document
/// for exactly that long, and it cannot parse `280ms ease` to find out how long
/// to wait.
public struct TransitionPhases: Hashable, Sendable {
    public let enter: String
    public let exit: String
    public let durationMilliseconds: Int

    public init(enter: String, exit: String, durationMilliseconds: Int) {
        self.enter = enter
        self.exit = exit
        self.durationMilliseconds = durationMilliseconds
    }
}
