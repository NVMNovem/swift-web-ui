# Dynamic Content With RemoteList

Render API-driven lists from Swift-defined markup.

## Overview

``Template`` defines inert browser markup that can be cloned later by generated JavaScript. Binding modifiers mark the places where JSON fields should be inserted:

```swift
Template("product-card") {
    Article {
        Text("")
            .bindText("name")

        Text("")
            .bindText("description")
    }
}
```

The static-only `RemoteList` type fetches a JSON array from a GET endpoint, finds the named template, clones it once per item, and fills bound fields. Import `SwiftWebUIStatic` to use it:

```swift
RemoteList(source: .get("/api/products"), template: "product-card")
    .loading {
        Text("Producten laden...")
    }
    .empty {
        Text("Geen producten gevonden.")
    }
    .error {
        Text("Kon producten niet laden.")
    }
```

Use `.bindText(_:)` for text content and `.bindAttribute(_:_:)` for attributes:

```swift
Link(destination: "#") {
    Text("View")
}
.bindAttribute("href", "url")
```

`RemoteList` belongs to `SwiftWebUIStatic`, not the Embedded core. It is intentionally not a JavaScript framework. It does not run Swift in the browser, compile Swift closures to JavaScript, evaluate arbitrary expressions, or provide a reactive runtime. The generated runtime uses `textContent` for text, avoids `eval`, expects a JSON array, and supports simple field names plus dot paths such as `category.name`.

## Topics

### Templates and Bindings

- ``Template``

### Architecture

- <doc:Architecture>
