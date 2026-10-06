import SwiftWebUI
import SwiftWebUIRuntime

#if arch(wasm32)
import JavaScriptEventLoop
#endif

/// The WebAssembly entry point: mounts `RootView` into `<div id="app">`.
@main
struct App {
    static func main() {
        #if arch(wasm32)
        // Swift Concurrency in the browser is driven by the JavaScript event
        // loop; without this executor an `await` never resumes.
        JavaScriptEventLoop.installGlobalExecutor()
        #endif

        // One root per page. Resources/index.html links styles.css itself, so
        // the page is styled before the bundle arrives; pass
        // `resources: RuntimeResources(stylesheets: [...])` for CSS that is only
        // known at run time.
        SwiftWebUIRuntime.mount(RootView(), in: "app")
    }
}
