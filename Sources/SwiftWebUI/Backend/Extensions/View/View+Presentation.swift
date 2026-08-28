//
//  View+Presentation.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 28/08/2026.
//

/// Presentation sugar over ``Dialog``.
public extension View {

    /// Presents `content` as a modal sheet over this view while `isPresented`
    /// is `true`.
    ///
    /// This is ``Dialog`` under a name people already expect from SwiftUI. The
    /// dialog is emitted beside the receiver rather than inside it, because a
    /// modal dialog is shown in the browser's top layer and its position in the
    /// document does not affect where it appears.
    func sheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: () -> Content
    ) -> Group<TupleView2<Self, Dialog<Content>>> {
        let sheetContent = content()
        let dialog = Dialog(isPresented: isPresented) { sheetContent }
        return Group { TupleView2(self, dialog) }
    }
}
