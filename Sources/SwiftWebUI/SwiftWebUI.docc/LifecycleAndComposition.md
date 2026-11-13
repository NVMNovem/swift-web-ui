# Lifecycle and Composition

Start work when a view appears, react to changes, package modifiers, and pass values
down the tree.

## Overview

These APIs have SwiftUI's names and shapes. Where Embedded Swift rules out SwiftUI's
spelling, which happens for key paths, the difference is noted.

### Starting work from a view

``View/task(priority:_:)`` starts an asynchronous task when its view appears and
cancels it when the view disappears:

```swift
struct ShopView: View {
    let service: StorefrontService
    @State private var shop: Shop?

    var body: some View {
        VStack {
            if let shop {
                ShopContent(shop: shop)
            } else {
                Text("Loading…")
            }
        }
        .task {
            shop = await service.shop()
        }
    }
}
```

A view therefore loads what it needs itself. An application no longer has to load
in `init()` and mount a second time once the data is there.

``View/task(id:priority:_:)`` also restarts the task when its `id` changes, after
cancelling the one that is running. ``View/onAppear(perform:)`` and
``View/onDisappear(perform:)`` are the synchronous counterparts.
``View/onChange(of:initial:_:)-(_,_,(V,V)->Void)`` calls its action with the old and
the new value when a build finds that a value changed.

When these run:

- A view *appears* when a build first reaches it at its structural position, and
  *disappears* when a build no longer does, or when the root unmounts. This is the
  identity that keeps `State` alive. See <doc:StateAndBindings>.
- Actions run and tasks start after the DOM shows the build, never inside a `body`.
  An action may write state, and the write schedules the next build.
- A task is not isolated to an actor, because Embedded Swift has no main actor. The
  browser has one thread, and everything the runtime starts runs on it.
- A static render runs none of them.

### Packaging modifiers

A ``ViewModifier`` packages a set of modifiers, or a wrapper, under one name:

```swift
struct Card: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.px(16))
            .background(.white)
            .cornerRadius(.px(12))
    }
}

extension View {
    func card() -> some View { modifier(Card()) }
}
```

A modifier is a composed view. It may declare `@State` and `@Environment`
properties, and its state belongs to the position where it is applied.
``ViewModifierContent`` stands for the modified view. It is the one place where
composition erases a view's type, because SwiftUI's `ViewModifier` requires it.

### Environment values

``Environment`` reads objects by their type. It reads values by an
``EnvironmentKey``:

```swift
struct AccentKey: EnvironmentKey {
    static let defaultValue = Color.blue
}

struct Badge: View {
    @Environment(AccentKey.self) private var accent

    var body: some View {
        Text("New").foregroundStyle(accent)
    }
}

Badge().environment(AccentKey.self, .red)
```

SwiftUI names the value with a key path into `EnvironmentValues`. Key paths are
unavailable in Embedded Swift, so the key type is the name here, as
`LocaleIdentifier.self` already is for the locale. A read never fails. Where no
ancestor placed a value, the read returns the key's `defaultValue`.

### One rebuild per frame

A state write or an observed change does not rebuild at once. It asks for a rebuild
on the browser's next animation frame. Every write before that frame shares the one
rebuild, which reads each value as it is by then. Two writes in one action cost one
rebuild.

## Topics

### Lifecycle

- ``View/onAppear(perform:)``
- ``View/onDisappear(perform:)``
- ``View/task(priority:_:)``
- ``View/task(id:priority:_:)``
- ``View/onChange(of:initial:_:)-(_,_,(V,V)->Void)``
- ``View/onChange(of:initial:_:)-(_,_,()->Void)``
- ``LifecycleView``

### Composition

- ``ViewModifier``
- ``View/modifier(_:)``
- ``ModifiedContent``
- ``ViewModifierContent``

### Environment

- ``Environment``
- ``EnvironmentKey``
- ``View/environment(_:_:)``
- ``EnvironmentValueWriter``
