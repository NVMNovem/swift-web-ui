# State and Bindings

Use SwiftWebUI state placeholders for initial values and generated client-state metadata.

## Overview

``State`` stores a value while Swift renders a view tree. Its projected value is a ``Binding`` that carries a generated client-state key.

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

SwiftWebUI state is not SwiftUI state and does not imply a browser-side Swift runtime. Binding-backed controls render initial state metadata and generated actions. The bundled runtime updates matching tab buttons and tab panels in the browser.

Use ``ClientStateValue`` when a custom value needs an explicit browser string representation. `String`, `Int`, and `Bool` already conform. Raw representable enums with `String` or `Int` raw values are also supported by convenience overloads.
