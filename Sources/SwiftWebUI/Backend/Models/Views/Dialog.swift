//
//  Dialog.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 28/08/2026.
//

/// A browser `dialog` element driven by a binding.
///
/// A modal dialog is worth reaching for rather than hand-rolling, because the
/// browser gives four things back that an application cannot correctly build for
/// itself: the top layer, so no `zIndex` guessing and no containing block created
/// by a transformed ancestor; a `::backdrop`; a focus trap; and an inert
/// background.
///
/// Presentation is reconciled, not called: the view reports what it wants and
/// the runtime performs `showModal()`, `show()`, or `close()`. The browser can
/// also close a dialog on its own — Escape, or its `cancel` event — so `Dialog`
/// writes `false` back through `isPresented` when that happens, which is the one
/// place the runtime pushes state upward.
///
/// > Important: A modal dialog is browser-runtime only. Static rendering can
/// > present a non-modal dialog with `<dialog open>`, but it has no top layer to
/// > show a modal one in, and omits it.
public struct Dialog<Content: View>: View {
    public typealias Body = Never
    public let isPresented: Binding<Bool>
    public let isModal: Bool
    public let content: Content

    public init(
        isPresented: Binding<Bool>,
        isModal: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.isPresented = isPresented
        self.isModal = isModal
        self.content = content()
    }

    public var body: Never { fatalError("Dialog primitive body unavailable") }

    public func makeViewNode(in context: ViewContext) -> ViewNode {
        let presentation: DialogPresentation
        if isPresented.wrappedValue {
            presentation = isModal ? .modal : .nonModal
        } else {
            presentation = .dismissed
        }
        let isPresented = isPresented
        return .container(.init(
            kind: .dialog(
                presentation: presentation,
                onDismiss: .closure { isPresented.wrappedValue = false }
            ),
            children: content.makeViewNode(in: context.content).groupChildren
        ))
    }
}
