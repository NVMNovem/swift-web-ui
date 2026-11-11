# Starter

The smallest SwiftWebUI application that runs in a browser: one `App`, one `Page`, a
counter. Copy this directory to start a site and replace the path dependency in
`Package.swift` with the released package.

```sh
swift package --swift-sdk <wasm sdk> js -c release
swift package --allow-writing-to-package-directory web
swift package --allow-network-connections local web-serve
```

See [Getting started in the browser](../../Documentation/GettingStarted.md).
