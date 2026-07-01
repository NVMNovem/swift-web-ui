# Building Navigation

Add links and selection tabs to a page.

## Overview

Use links for browser navigation and tab bars for selection controls.

```swift
import SwiftWebUI

enum SiteSection: String {
    case home
    case about
}

struct NavigationExample: View {
    var body: some View {
        VStack(alignment: .leading, spacing: .px(16)) {
            Link("Home", destination: "/")

            Link(destination: "/about") {
                Text("About us")
                    .semanticRole(.p)
            }

            TabBar(selection: SiteSection.home) {
                Tab("Home", value: .home)
                Tab("About", value: .about)
            }
        }
    }
}
```

## Discussion

``Link`` renders an anchor. ``TabBar`` renders tab controls and selected-state attributes, but it does not render content panels. Use ``TabView`` for tabs that own panels.
