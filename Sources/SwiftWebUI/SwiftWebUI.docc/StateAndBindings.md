# State and Bindings

Use renderer-neutral state, bindings, and action intent.

## Overview

``State`` is owned by the mounted root, not by the view struct, so it survives at any depth. Its projected value is a ``Binding`` with closure-backed access and stable state identity.

```swift
enum ProfileTab: String {
    case details
    case reviews
}

struct ProfilePage: View {
    @State private var selection = ProfileTab.details

    var body: some View {
        TabView(selection: $selection) {
            Tab("Details", value: .details) {
                Text("Details")
            }
            Tab("Reviews", value: .reviews) {
                Text("Reviews")
            }
        }
    }
}
```

## Topics

### State Values

- ``State``
- ``Binding``
- ``ClientStateValue``
- ``ClientStateBinding``
- ``ClientStateMutation``

### State Identity

- ``StateSlotStore``
- ``ViewContext``
- ``ViewIdentityPath``
- ``ViewPathComponent``
- ``ViewIdentityToken``
- ``ViewIdentifiable``

### Client-State Views

- ``Tab``
- ``TabBar``
- ``TabView``

## Discussion

SwiftWebUI state is not SwiftUI state. Binding-backed controls preserve initial value and identity in ``ViewNode``. `SwiftWebUIStatic` converts supported intent into data attributes and a generated tab runtime.

`SwiftWebUIRuntime` installs one renderer-neutral invalidation callback. Mutating ``State`` or its projected ``Binding`` invokes that callback, rebuilds and lowers the root ``ViewNode``, diffs the previous and new `WebNode`, and applies positional patches to a runtime-only mounted tree. Unchanged browser elements remain mounted. This reconciler still does not provide child moves, multiple roots, or production lifecycle semantics.

### State slots

A view struct is rebuilt from scratch on every invalidation, so storage held inside it cannot survive. A mounted root instead owns a ``StateSlotStore`` that keys storage on the view's structural identity: a rebuilt view at the same position resolves to the same box.

Identity is a ``ViewIdentityPath`` built during lowering. It descends through builder carriers, so sibling views, `if`/`else` branches, and keyed collection elements are all distinct. State resets exactly when a view's structural position genuinely changes -- flipping an `if`/`else` branch gives the new branch fresh state.

Slots are reclaimed by view liveness, not by whether a state was read. A view that renders without touching one of its own states keeps it:

```swift
struct DetailRow: View {
    @State private var expanded = false
    @State private var draft = ""

    var body: some View {
        VStack {
            Button("Toggle") { expanded.toggle() }
            if expanded {
                TextArea()   // `draft` is only read on this branch
            }
        }
    }
}
```

Binding is lazy: a view is constructed while its *parent's* `body` runs, so its own identity is only available once its own `body` is evaluated. Two consequences follow.

A state that is never read or projected during `body` never binds, and falls back to per-rebuild storage. Because such a state cannot affect rendering, the effect is only observable through side effects in actions. If a state is written from an action but rendered only on some branches, read it unconditionally somewhere in `body`.

When no store is installed -- static rendering, or lowering a view directly -- every state uses private per-instance storage, which is the pre-slot behavior.

Each write still rebuilds the whole root; writes are not yet coalesced, so two mutations in one action run the pipeline twice.

### Collection identity

``ForEach`` keys rows by position unless given identity, so inserting or removing an element shifts the state of every row after it. Pass `id:`, or use elements conforming to `Identifiable`, when rows own state:

```swift
ForEach(items, id: { $0.sku }) { item in
    QuantityStepper(item: item)
}
```

Key types conform to ``ViewIdentifiable``. `Int` and `String` conform already, and raw-representable types with `Int` or `String` raw values get an implementation for free.

Use ``ClientStateValue`` when a value needs an explicit concrete ``ClientValue``. `String`, `Int`, and `Bool` already conform. Raw representable enums with `String` or `Int` raw values are supported by control overloads. The core does not use dynamic casts or `String(describing:)` fallback serialization.
