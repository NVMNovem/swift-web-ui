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

Set the browser tab title from the view that supplies the page:

```swift
VStack {
    Text("Projects")
        .semanticRole(.h1)
}
.navigationTitle("Projects")
```

Static rendering carries the title into `RenderedView`; `WebDocument` emits it
as `<title>` unless the document was given an explicit title. A runtime mount
sets `document.title` and reconciles it when state rebuilds the view. When more
than one active child supplies a title, the last child wins; a title on their
containing view overrides its descendants.

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

### Page Title

- ``View/navigationTitle(_:)``

### Tab Navigation

- ``Tab``
- ``TabBar``
- <doc:Tabs>

## Discussion

`TabBar(selection:)` renders tab controls without owning matching panels. Use ``TabView`` when the component should render both controls and panels.
