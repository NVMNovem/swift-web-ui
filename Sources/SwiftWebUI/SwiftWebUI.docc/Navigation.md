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

Set a browser tab icon with ``View/navigationIcon(_:)``. `.svg` takes literal
SVG markup and renders it as a data URL with the SVG MIME type. `.url` takes a
browser-resolvable asset path or URL and leaves type selection to the browser.
Application build tooling must copy local files into the served output.

```swift
VStack {
    Text("Projects")
}
.navigationTitle("Projects")
.navigationIcon(.svg("<svg viewBox=\"0 0 16 16\"><circle cx=\"8\" cy=\"8\" r=\"8\"/></svg>"))
```

Static documents emit the favicon link in their head. A runtime mount installs
and reconciles one managed favicon link, then removes it when the mounted root
stops so the host document can resume control.

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
- ``View/navigationIcon(_:)``
- ``NavigationIcon``

### Tab Navigation

- ``Tab``
- ``TabBar``
- <doc:Tabs>

## Discussion

`TabBar(selection:)` renders tab controls without owning matching panels. Use ``TabView`` when the component should render both controls and panels.
