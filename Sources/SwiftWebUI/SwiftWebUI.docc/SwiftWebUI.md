# ``SwiftWebUI``

Build renderer-neutral web UI with an Embedded-compatible SwiftUI-like DSL.

## Overview

Views preserve concrete composition and lower to ``ViewNode``:

```swift
import SwiftWebUI

struct CounterView: View {
    @State private var count = 0

    var body: some View {
        VStack(alignment: .leading, spacing: .px(8)) {
            Text("Count").semanticRole(.h1)

            if count == 0 {
                Text("Zero")
            } else {
                Text("Non-zero")
            }

            Button("Increment") { count += 1 }
        }
        .padding(.px(8))
    }
}

let node = CounterView().makeViewNode()
```

The shared module contains no HTML strings, generated JavaScript, filesystem code, or DOM objects. Import `SwiftWebUIStatic` in an application that needs `HTMLRenderer`, `WebDocument`, static resources, or preview export; that module re-exports this DSL. Import `SwiftWebUIRuntime` in a browser Wasm application to use the deliberately limited first mounting and rerender proof of concept.

Normal composition uses fixed-arity generic carriers rather than `AnyView` or view existentials. Swift 6.3.3 Embedded currently requires this compatibility design for result-builder specialization.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Architecture>
- ``View``
- ``ViewBuilder``
- ``ViewNode``
- ``ViewRendererProtocol``

### Building Views

- <doc:Components>
- <doc:Layout>
- ``Text``
- ``Image``
- ``Link``
- ``Button``
- ``Group``
- ``VStack``
- ``HStack``
- ``ZStack``
- ``Grid``
- ``Article``
- ``Section``
- ``Form``
- ``Label``
- ``Input``
- ``TextArea``
- ``Footer``
- ``Template``

### Composition and Modifiers

- ``ModifiedView``
- ``OptionalView``
- ``ConditionalView``
- ``ArrayView``
- ``ForEach``
- ``ViewModifierNode``
- <doc:Styling>

### State and Controls

- <doc:StateAndBindings>
- <doc:Navigation>
- <doc:Presentation>
- <doc:Tabs>
- <doc:Forms>
- ``State``
- ``Binding``
- ``ActionIntent``
- ``Tab``
- ``TabBar``
- ``TabView``
- ``Dialog``
- ``DialogPresentation``

### More

- <doc:AdvancedTopics>
- <doc:ContributorGuide>
- <doc:BuildingYourFirstPage>
- <doc:BuildingNavigation>
- <doc:BuildingAContactForm>
- <doc:BuildingATabInterface>
