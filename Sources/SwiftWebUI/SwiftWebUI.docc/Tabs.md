# Tabs

Use `TabBar` for selection controls and `TabView` for tabbed content.

## Overview

``TabBar`` renders accessible tab controls:

```swift
enum PageTab: String {
    case home
    case about
}

TabBar(selection: PageTab.home) {
    Tab("Home", value: .home)
    Tab("About", value: .about)
}
```

``TabView`` renders both tab controls and matching panels:

```swift
enum ProductTab: String {
    case details
    case reviews
}

TabView(selection: ProductTab.details) {
    Tab("Details", value: .details) {
        Text("Product details")
    }
    Tab("Reviews", value: .reviews) {
        Text("Customer reviews")
    }
}
```

## Topics

### Tab Components

- ``Tab``
- ``TabBar``
- ``TabView``
- ``State``
- ``Binding``

## Discussion

Static selection initializers render the selected state once. Binding initializers also render generated data attributes and register the client-state runtime so buttons can update selected tab state in the browser.

The runtime is intentionally small. It updates tab controls and panels for generated `set-state` actions; it does not evaluate arbitrary Swift code.
