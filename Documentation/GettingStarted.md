# Getting started in the browser

A SwiftWebUI application that runs in the browser is one SwiftPM package, one `App`,
and two commands. `Examples/Starter` is this guide as a package you can copy.

## 1. The package

```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MySite",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/NVMNovem/swift-web-ui.git", from: "<version>"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", from: "0.56.1"),
    ],
    targets: [
        .executableTarget(
            name: "MySite",
            dependencies: [
                .product(name: "SwiftWebUI", package: "swift-web-ui"),
                .product(name: "SwiftWebUIRuntime", package: "swift-web-ui"),
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
            ]
        ),
    ]
)
```

JavaScriptKit is listed because SwiftPM only offers a package the command plugins of
its direct dependencies, and `swift package js`, used below, is JavaScriptKit's. No
linker flags are needed: that command passes the ones a browser build requires.

## 2. The application

```swift
import SwiftWebUI
import SwiftWebUIRuntime

@main
struct MySite: App {
    var body: some Scene {
        Page {
            Counter()
        }
        .stylesheet(.external("styles.css"))
    }
}

struct Counter: View {
    @State private var count = 0

    var body: some View {
        VStack(alignment: .leading, spacing: .px(16)) {
            Text(verbatim: "Pressed \(count) times")
            Button("Press") { count += 1 }
        }
        .padding(.px(24))
    }
}
```

`App` is SwiftUI's `App`. `Page` stands where `WindowGroup` does: a browser tab shows
one document, so the scene is a page. `App` supplies `main()`, which installs the
JavaScript event loop for Swift Concurrency, creates the application and mounts the
page into the element with the id `app`.

Files the page needs — a stylesheet, images, fonts — go in `Resources/`. They are
copied into the output as they are, so `Resources/styles.css` is served as
`/styles.css`, which is the address `.stylesheet(.external("styles.css"))` asks for.

## 3. Build and assemble

```sh
# Once: a WebAssembly SDK matching your toolchain.
swift sdk list

# Compile to WebAssembly. This is JavaScriptKit's command.
swift package --swift-sdk <wasm sdk> js -c release

# Assemble dist/. This is SwiftWebUI's.
swift package --allow-writing-to-package-directory web
```

`swift package web` takes what `swift package js` built and adds what a browser needs
around it:

- everything in `Resources/`;
- an `index.html` with a loading screen that paints before any WebAssembly has
  arrived, the mount point, and a loader that reports download progress;
- the WASI shim JavaScriptKit's browser code imports, from `Vendor/browser_wasi_shim`
  when the package has one, and from a public CDN — with a warning — when it does
  not;
- a size report, and a failure when `--max-bytes` is given and exceeded.

The result is `dist/`: static files for any host. Run `swift package web --help` for
the options, among them `--title`, `--language`, `--mount-point` and `--base-path` for
a site served under a path.

To bring your own document, put an `index.html` in `Resources/`. It is used as it is
and none is generated. It has to carry the mount point and start the bundle itself;
`SwiftWebUIStatic.WebDocument` can render one from Swift.

## 4. Look at it

```sh
swift package --allow-network-connections local web-serve
```

serves `dist/` on <http://127.0.0.1:8080>, answering unknown paths with `index.html`
so an application that reads the address can be opened at any of its URLs. It needs
`python3` and is for development only.

## Size

Release builds are optimized by JavaScriptKit with `wasm-opt` **when it is installed**;
without it the build prints a warning and ships the unoptimized file. Install Binaryen
(`brew install binaryen`) on every machine that builds a bundle.

The single largest cost is Foundation: importing it anywhere in what the executable
links adds several megabytes. `swift package web --max-bytes <count>` turns a budget
into a build failure, which is the cheapest way to notice.

## What `App` does not do yet

- A view cannot start asynchronous work of its own; there is no `.task`. Start it from
  the application's `init()`, which runs after the event loop is installed, and hand
  the result to the views through an observable model.
- One page per application. Routing between addresses is the application's.
