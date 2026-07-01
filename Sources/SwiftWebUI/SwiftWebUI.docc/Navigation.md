# Navigation

Create links and selection-only tab controls for browser navigation patterns.

## Overview

Use ``Link`` for anchors:

```swift
Link("Website", destination: "https://example.com")
```

Use the container form when the anchor wraps nested content:

```swift
Link(destination: "https://example.com/project") {
    Article {
        Image("assets/project.jpg", alt: "Project preview")
        Text("Project")
            .semanticRole(.h2)
    }
}
.attribute("target", "_blank")
.attribute("rel", "noreferrer")
```

Use ``TabBar`` for selection-only navigation, filters, segmented controls, and timeline selectors:

```swift
enum SectionID: String {
    case home
    case about
}

TabBar(selection: SectionID.home) {
    Tab("Home", value: .home)
    Tab("About", value: .about)
}
```

## Topics

### Links

- ``Link``

### Tab Navigation

- ``Tab``
- ``TabBar``
- <doc:Tabs>

## Discussion

`TabBar(selection:)` renders tab controls without owning matching panels. Use ``TabView`` when the component should render both controls and panels.
