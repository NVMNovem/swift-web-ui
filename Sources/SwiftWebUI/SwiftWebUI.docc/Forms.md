# Forms

Render static browser form markup with generic form primitives.

## Overview

SwiftWebUI includes basic semantic form views:

```swift
Form {
    Label("Name")
        .attribute("for", "contact-name")

    Input()
        .id("contact-name")
        .attribute("type", "text")
        .attribute("name", "name")
        .attribute("autocomplete", "name")
        .attribute("required", "")

    Label("Message")
        .attribute("for", "contact-message")

    TextArea()
        .id("contact-message")
        .attribute("name", "message")
        .attribute("required", "")

    Button("Send")
        .attribute("type", "submit")
}
.attribute("method", "post")
```

## Topics

### Form Views

- ``Form``
- ``Label``
- ``Input``
- ``TextArea``
- ``Button``

## Discussion

``Button`` also accepts a content closure for controls whose label is not a
plain string:

```swift
Button(action: submit) {
    HStack(spacing: .px(6)) {
        Image("send.svg", alt: "")
        Text("Send")
    }
}
```

### Focus

`.defaultFocus()` asks for focus once the element is in a live document — the
usual case being a panel that should put the caret in its first field as it
appears:

```swift
Input()
    .id("contact-name")
    .attribute("type", "text")
    .defaultFocus()
```

It is deliberately one-way. Nothing reads focus back out of the DOM, so it needs
no state channel and cannot disagree with the view tree.

The runtime calls `focus()` on the element after inserting it, and only on the
transition into asking for focus: an element that already had focus requested
keeps it across rerenders, so an unrelated state change never yanks focus back
mid-typing.

> Important: This is not the `autofocus` attribute. Browsers honour `autofocus`
> at parse time, not when a node is inserted into a live document, so it is no
> substitute for a panel that appears later. Static rendering does emit
> `autofocus` — with no live document to move focus in, that is the honest
> equivalent there, and it is the one place the two backends differ.

### Keys

`.onKeyDown(_:perform:)` runs a closure when the element sees a key-down for one
key, named by the DOM's own `KeyboardEvent.key` string:

```swift
Div {
    Text("Panel")
}
.attribute("tabindex", "-1")
.defaultFocus()
.onKeyDown("Escape") { isPresented = false }
```

The handler is scoped to the element, so it only fires while focus is inside it.
That is why the example above is focusable: a `tabindex` of `-1` makes an
otherwise non-interactive container a focus target without putting it in the tab
order, and ``View/defaultFocus()`` puts the caret there as it appears. Prefer
this to a document-level listener — a scoped handler dies with the view, where a
document one outlives it.

Handlers replace conservatively on every rerender that carries one, for the same
reason click actions do: a closure has no renderer-neutral identity, so "the same
key with some closure" cannot be shown to be the same closure. Removing the
subtree releases every registration it holds.

> Important: Key handling is browser-runtime only. Static rendering emits no key
> handler and no placeholder attribute.

Typed form attributes are intentionally deferred. Use `.attribute(_:_:)` for valid HTML attributes that do not have dedicated SwiftWebUI modifiers yet.

> Important: Form submission behavior is browser behavior. SwiftWebUI renders markup and resources; it does not provide a server, validation runtime, or request handler.
