//
//  View+Layering.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 28/08/2026.
//

/// Layering sugar over ``ZStack``.
///
/// These are view composition, not styling, so they carry no
/// ``ViewModifierNode`` case: each one builds a ``ZStack`` whose children are
/// the receiver and the closure's content, in paint order.
public extension View {

    /// Paints `content` over this view, in the same box.
    ///
    /// The stack sizes itself to whichever of the two is larger, so neither
    /// layer needs to know the other's position.
    func overlay<Overlay: View>(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> Overlay
    ) -> ZStack<TupleView2<Self, Overlay>> {
        let overlay = content()
        return ZStack(alignment: alignment) { TupleView2(self, overlay) }
    }

    /// Paints `content` behind this view, in the same box.
    func background<BackgroundContent: View>(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> BackgroundContent
    ) -> ZStack<TupleView2<BackgroundContent, Self>> {
        let background = content()
        return ZStack(alignment: alignment) { TupleView2(background, self) }
    }
}
