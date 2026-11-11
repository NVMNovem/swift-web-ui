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

There is no `.task` modifier yet, so a view cannot start work of its own. The
application's `init()` runs after the event loop is installed, so it can start a
`Task` that loads into an observable model the views read. The page is mounted at
once in whatever state that model starts in, and rebuilds when the model changes.
In the Swift 6 language mode, what the task captures has to be `Sendable`.

### Building

`swift package js` from JavaScriptKit compiles the package to WebAssembly, and
`swift package web` from this package assembles the deployable directory around it,
including the document that carries the mount point. `Documentation/GettingStarted.md`
in the repository walks through both.
