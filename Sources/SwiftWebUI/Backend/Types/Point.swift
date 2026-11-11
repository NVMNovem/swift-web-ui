//
//  Point.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

/// A position in a view's own coordinate space, in CSS pixels.
///
/// Where SwiftUI hands over a `CGPoint` — the location of a drop — SwiftWebUI
/// hands over a `Point`, so `location.x` and `location.y` read the same. It is not
/// called `CGPoint` because Foundation already declares one, and a file that
/// imports both would not compile.
///
/// The origin is the top-left corner of the view's border box; `x` grows to the
/// right and `y` grows downward, as in SwiftUI.
public struct Point: Hashable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    /// The origin, `(0, 0)`.
    public static let zero = Point(x: 0, y: 0)
}
