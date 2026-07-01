# Building a Tab Interface

Render tab controls and matching panels with TabView.

## Overview

Use ``TabView`` when the component owns both the controls and panels.

```swift
import SwiftWebUI

enum ProductTab: String {
    case details
    case reviews
}

struct ProductTabs: View {
    @State private var selection = ProductTab.details

    var body: some View {
        TabView(selection: $selection) {
            Tab("Details", value: .details) {
                Text("DetailsView")
            }
            Tab("Reviews", value: .reviews) {
                Text("ReviewsView")
            }
        }
    }
}
```

## Discussion

The binding-backed initializer renders generated state metadata and registers the client-state runtime. That runtime updates selected tabs and hides or shows matching panels in the browser.
