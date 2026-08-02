# State and Bindings

Use renderer-neutral state, bindings, and action intent.

## Overview

``State`` uses reference-backed storage. Its projected value is a ``Binding`` with closure-backed access and stable state identity.

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

### Client-State Views

- ``Tab``
- ``TabBar``
- ``TabView``

## Discussion

SwiftWebUI state is not SwiftUI state. Binding-backed controls preserve initial value and identity in ``ViewNode``. `SwiftWebUIStatic` converts supported intent into data attributes and a generated tab runtime.

`SwiftWebUIRuntime` installs one renderer-neutral invalidation callback. Mutating ``State`` or its projected ``Binding`` invokes that callback, rebuilds and lowers the root ``ViewNode``, diffs the previous and new `WebNode`, and applies positional patches to a runtime-only mounted tree. Unchanged browser elements remain mounted. This first reconciler does not provide keyed identity, state slots, moves, multiple roots, or production lifecycle semantics.

Use ``ClientStateValue`` when a value needs an explicit concrete ``ClientValue``. `String`, `Int`, and `Bool` already conform. Raw representable enums with `String` or `Int` raw values are supported by control overloads. The core does not use dynamic casts or `String(describing:)` fallback serialization.
