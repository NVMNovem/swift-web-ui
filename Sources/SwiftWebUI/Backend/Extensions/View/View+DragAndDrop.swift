//
//  View+DragAndDrop.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

public extension View {
    /// Lets the reader drag this view, carrying what `data` provides.
    ///
    /// SwiftUI's `onDrag(_:)`. `data` runs when a drag starts, so it reads the
    /// content as it is then:
    ///
    /// ```swift
    /// Text(card.title)
    ///     .onDrag { ItemProvider(object: card.id) }
    /// ```
    ///
    /// The view becomes a native HTML drag source: it lowers with
    /// `draggable="true"`, and when the browser starts a drag, every
    /// representation the provider carries is written to the drag's
    /// `DataTransfer` under its MIME type. Because it is a browser drag, the
    /// content can be dropped on other pages and applications as well.
    ///
    /// The browser draws the drag preview from the element itself; SwiftUI's
    /// `onDrag(_:preview:)` is not available. When a view has more than one
    /// `onDrag`, the one nearest the view wins, as in SwiftUI.
    ///
    /// Browser-runtime only. A static document renders `draggable="true"` but has
    /// nothing to put in the drag.
    func onDrag(_ data: @escaping () -> ItemProvider) -> ModifiedView<Self> {
        ModifiedView(content: self, modifiers: [.onDrag(DragSource(EnvironmentStorage.capturing(data)))])
    }

    /// Accepts drops of the given content types, calling `action` with what was dropped.
    ///
    /// SwiftUI's `onDrop(of:isTargeted:perform:)`:
    ///
    /// ```swift
    /// @State private var isTargeted = false
    ///
    /// VStack { … }
    ///     .background(isTargeted ? .blue : .white)
    ///     .onDrop(of: [.plainText], isTargeted: $isTargeted) { providers in
    ///         providers.first?.loadObject(ofClass: String.self) { id in
    ///             if let id { moveCard(id) }
    ///         }
    ///         return true
    ///     }
    /// ```
    ///
    /// Only a drag carrying content that conforms to one of
    /// `supportedContentTypes` is accepted; any other is refused without
    /// calling anything. While an accepted drag is over the view, `isTargeted` is
    /// `true`. The providers passed to `action` carry only the conforming content.
    ///
    /// The returned `Bool` says whether the drop was handled. The browser has
    /// already handed the content over by then, so `false` does not give it back.
    ///
    /// Dropped files are not supported yet.
    ///
    /// Browser-runtime only. Static rendering emits no drop handler.
    func onDrop(
        of supportedContentTypes: [UTType],
        isTargeted: Binding<Bool>?,
        perform action: @escaping ([ItemProvider]) -> Bool
    ) -> ModifiedView<Self> {
        onDrop(of: supportedContentTypes, isTargeted: isTargeted) { providers, _ in action(providers) }
    }

    /// Accepts drops of the given content types, calling `action` with what was
    /// dropped and where.
    ///
    /// SwiftUI's `onDrop(of:isTargeted:perform:)` with a location. The location
    /// is in the view's own coordinate space, in CSS pixels from its top-left
    /// corner. Otherwise the same as the form whose `action` takes only the
    /// providers.
    func onDrop(
        of supportedContentTypes: [UTType],
        isTargeted: Binding<Bool>?,
        perform action: @escaping ([ItemProvider], Point) -> Bool
    ) -> ModifiedView<Self> {
        onDrop(
            of: supportedContentTypes,
            delegate: ActionDropDelegate(
                supportedContentTypes: supportedContentTypes,
                isTargeted: isTargeted,
                action: action
            )
        )
    }

    /// Accepts drops of the given content types, letting `delegate` take part at
    /// every step.
    ///
    /// SwiftUI's `onDrop(of:delegate:)`. See ``DropDelegate`` for the order of
    /// the calls. A drag carrying nothing that conforms to
    /// `supportedContentTypes` never reaches the delegate.
    ///
    /// When a view has more than one `onDrop`, the one nearest the view wins, as
    /// in SwiftUI.
    ///
    /// Browser-runtime only. Static rendering emits no drop handler.
    func onDrop<Delegate: DropDelegate>(
        of supportedContentTypes: [UTType],
        delegate: Delegate
    ) -> ModifiedView<Self> {
        ModifiedView(content: self, modifiers: [.onDrop(DropTarget(of: supportedContentTypes, delegate: delegate))])
    }
}

/// The delegate behind the closure-based `onDrop` modifiers.
private struct ActionDropDelegate: DropDelegate {
    let supportedContentTypes: [UTType]
    let isTargeted: Binding<Bool>?
    let action: ([ItemProvider], Point) -> Bool

    func dropEntered(info: DropInfo) {
        isTargeted?.wrappedValue = true
    }

    func dropExited(info: DropInfo) {
        isTargeted?.wrappedValue = false
    }

    func performDrop(info: DropInfo) -> Bool {
        isTargeted?.wrappedValue = false
        return action(info.itemProviders(for: supportedContentTypes), info.location)
    }
}
