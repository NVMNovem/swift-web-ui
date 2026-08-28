# Presentation

Present a sheet over the page with a real browser dialog.

## Overview

``Dialog`` is a browser `dialog` element driven by a binding, and
``View/sheet(isPresented:content:)`` is the same thing under the name people
already expect from SwiftUI:

```swift
struct AccountPanel: View {
    @State private var isSignInPresented = false

    var body: some View {
        Button("Sign in") { isSignInPresented = true }
            .sheet(isPresented: $isSignInPresented) {
                VStack(alignment: .leading, spacing: .px(16)) {
                    Text("Sign in").semanticRole(.h2)

                    Input()
                        .attribute("type", "email")
                        .defaultFocus()

                    Button("Continue") { isSignInPresented = false }
                }
                .padding(.px(24))
            }
    }
}
```

## Topics

### Presentation

- ``Dialog``
- ``DialogPresentation``

## Discussion

### Why a real dialog

Hand-rolling a modal loses four things at once, and a `dialog` presented with
`showModal()` gives all four back:

- the **top layer**, so there is no `zIndex` to guess and no transformed
  ancestor that can quietly become the containing block;
- a **`::backdrop`**, styled by the runtime's own stylesheet;
- a **focus trap**, so Tab cannot walk out of the sheet;
- an **inert background**, so nothing behind it is clickable.

The runtime adds the page's scroll lock on top, so the content behind an open
sheet does not scroll. None of that is behaviour an application can correctly
implement on its own.

### Presentation is reconciled, not called

`showModal()` is imperative and the mounter is declarative, so presentation is
modelled the way focus is: as state carried on the element. A view says which
``DialogPresentation`` it wants, and the mounter and differ decide whether to
call `showModal()`, `show()`, or `close()` — after the element is in the
document, because presenting a detached node throws.

### The browser can close a dialog without asking

Escape, the backdrop, and the `cancel` event are the browser's own dismissal
paths, and none of them go through the binding. ``Dialog`` therefore registers a
close handler that writes `false` back — the one place the runtime pushes state
*upward*, taking the same invalidation hop a click action takes. Without it the
DOM and the view tree disagree, and the next rebuild re-opens a sheet the reader
just closed.

### Escape, explicitly

A modal dialog already closes on Escape by itself. Use
``View/onKeyDown(_:perform:)`` when a panel needs to do something more than
close — the dialog is lowered with `tabindex="-1"` so a key handler scoped to it
can actually see a key.

### Theming the backdrop

`::backdrop` is a pseudo-element and cannot be reached by an inline style, so the
runtime installs a named rule ahead of every application stylesheet. Recolour it
with a custom property, or override the rule outright:

```css
:root { --swiftwebui-dialog-backdrop: rgba(12, 14, 20, 0.6); }
```

### Animating a sheet

A dialog is removed like anything else, so
``View/transition(enter:exit:durationMilliseconds:)`` gives it an arrival and a
departure that a synchronous removal would otherwise never allow. See
<doc:Styling>.

> Important: A modal dialog is browser-runtime only. Static rendering has no top
> layer to show one in, so ``HTMLRenderer`` omits a presented modal dialog
> entirely rather than emitting a closed `dialog` that implies the content is
> there. A non-modal dialog renders as `<dialog open>`, and a dismissed one as a
> closed `<dialog>`.
