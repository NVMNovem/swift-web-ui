# Starting an application

Declare the application once and let the runtime start it.

## Overview

Conform one type to ``App``, mark it `@main`, and return a ``Page`` from its `body`:

```swift
import SwiftWebUI
import SwiftWebUIRuntime

@main
struct ShopApp: App {
    var body: some Scene {
        Page {
            RootView()
        }
        .stylesheet(.external("styles.css"))
    }
}
```

``Page`` stands where SwiftUI has `WindowGroup`. A browser tab shows one document at
one address, so the scene is named for that.

``App`` supplies `main()`. It installs the JavaScript event loop as Swift
Concurrency's executor, creates the application, and mounts the page's content into
the element whose `id` is the page's mount point — `app` unless
``Page/mountPoint(_:)`` says otherwise. Stylesheets added with
``Page/stylesheet(_:)`` are installed first, in order.

### Loading data

A view starts the work it needs with `.task`. The task starts once the page shows
the view and is cancelled when the view goes away. It writes what it loads into the
view's `State`, or into an observable model:

```swift
struct RootView: View {
    @State private var shop: Shop?

    var body: some View {
        Text(shop?.name ?? "Loading…")
            .task { shop = await loadShop() }
    }
}
```

The page is mounted once, showing the loading state, and rebuilds when the task
writes. The application's `init()` also runs after the event loop is installed, so
work that belongs to no view can still start there with `Task { … }`.

### Building

`swift package js` from JavaScriptKit compiles the package to WebAssembly, and
`swift package web` from this package assembles the deployable directory around it,
including the document that carries the mount point. `Documentation/GettingStarted.md`
in the repository walks through both.
