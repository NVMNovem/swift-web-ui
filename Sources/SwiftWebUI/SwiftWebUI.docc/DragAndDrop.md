# Drag and Drop

Let the reader drag views and drop content on them, with SwiftUI's
`onDrag` and `onDrop` modifiers.

## Overview

``View/onDrag(_:)`` makes a view a drag source and the `onDrop` modifiers make one
a drop destination. They take the same arguments as in SwiftUI, and they lower to
the browser's own HTML drag and drop: the source gets `draggable="true"`, and what
it carries travels in the drag's `DataTransfer`. That makes it a real browser
drag — content can come from, and go to, other pages and applications.

```swift
struct Board: View {
    @State private var done: [String] = []
    @State private var isTargeted = false

    var body: some View {
        VStack {
            Text("Write the release notes")
                .onDrag { ItemProvider(object: "release-notes") }

            VStack {
                Text("Done")
                ForEach(done, id: { $0 }) { Text($0) }
            }
            .background(isTargeted ? .hex("#e0ecff") : .hex("#ffffff"))
            .onDrop(of: [.plainText], isTargeted: $isTargeted) { providers in
                providers.first?.loadObject(ofClass: String.self) { id in
                    if let id { done.append(id) }
                }
                return true
            }
        }
    }
}
```

Drag and drop is browser-runtime only. A static document renders a source's
`draggable` attribute but nothing to put in the drag, and no drop handling at all.

### Content and content types

A browser drag carries text keyed by MIME type, and the types follow from that.
``ItemProvider`` is the counterpart of Foundation's `NSItemProvider`; every
representation it holds is a `String`. ``UTType`` is the counterpart of
`UniformTypeIdentifiers.UTType`, and its ``UTType/identifier`` is a MIME type
(`text/plain`), not an Apple identifier (`public.plain-text`). The common types —
``UTType/plainText``, ``UTType/url``, ``UTType/html``, ``UTType/json`` — are
there by name, and ``UTType/init(mimeType:)`` names any other.

Matching ignores MIME parameters, and two abstract types exist to be matched
against: ``UTType/text`` accepts any `text/…` content and ``UTType/item`` accepts
anything.

Loading never waits. The browser hands over a drop's content all at once, so an
``ItemProvider`` calls a completion handler before its loading method returns.

### Taking part in every step

``View/onDrop(of:delegate:)`` hands the drop to a ``DropDelegate``, which hears
about every step: ``DropDelegate/validateDrop(info:)``,
``DropDelegate/dropEntered(info:)``, ``DropDelegate/dropUpdated(info:)``,
``DropDelegate/dropExited(info:)`` and ``DropDelegate/performDrop(info:)``.
Returning a ``DropProposal`` from `dropUpdated` chooses the operation the pointer
shows: ``DropOperation/copy`` or ``DropOperation/move``, or
``DropOperation/forbidden`` to refuse the drop where the pointer is now.

```swift
struct ReorderDelegate: DropDelegate {
    let rowID: String
    let move: (_ id: String, _ before: String) -> Void

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [.plainText]).first else { return false }
        provider.loadObject(ofClass: String.self) { id in
            if let id { move(id, rowID) }
        }
        return true
    }
}

Text(row.title)
    .onDrag { ItemProvider(object: row.id) }
    .onDrop(of: [.plainText], delegate: ReorderDelegate(rowID: row.id, move: moveRow))
```

``DropInfo/location`` is a ``Point`` in the destination's own coordinate space, in
CSS pixels from its top-left corner — where SwiftUI hands over a `CGPoint`.

### Where the browser differs

- **What a drag carries is only readable once it is dropped.** Before then
  ``DropInfo/hasItemsConforming(to:)`` knows which kinds of content are coming,
  but ``DropInfo/itemProviders(for:)`` is empty until
  ``DropDelegate/performDrop(info:)``.
- **A drag is one item.** It can carry several representations, but the
  providers handed to a drop number at most one.
- **The preview is the element itself.** SwiftUI's `onDrag(_:preview:)` is not
  available; the browser draws the drag image from the dragged element.
- **Returning `false` from a drop does not undo it.** By the time the drop
  handler runs, the browser has handed the content over.
- **Dropped files are not supported yet.** A drag of files from the desktop
  carries no representation an ``ItemProvider`` can hold, so it is refused.

When one view has more than one `onDrag`, or more than one `onDrop`, the one
nearest the view wins, as in SwiftUI. Nested destinations each take the drags
over themselves: an accepted drag is not also offered to the destinations around
it.

## Topics

### Dragging

- ``View/onDrag(_:)``
- ``ItemProvider``

### Dropping

- ``View/onDrop(of:delegate:)``
- ``DropDelegate``
- ``DropInfo``
- ``DropProposal``
- ``DropOperation``

### Content

- ``UTType``
- ``Point``
