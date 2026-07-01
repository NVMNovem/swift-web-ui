# Forms

Render static browser form markup with generic form primitives.

## Overview

SwiftWebUI includes basic semantic form views:

```swift
Form {
    Label("Name")
        .attribute("for", "contact-name")

    Input()
        .id("contact-name")
        .attribute("type", "text")
        .attribute("name", "name")
        .attribute("autocomplete", "name")
        .attribute("required", "")

    Label("Message")
        .attribute("for", "contact-message")

    TextArea()
        .id("contact-message")
        .attribute("name", "message")
        .attribute("required", "")

    Button("Send")
        .attribute("type", "submit")
}
.attribute("method", "post")
```

## Topics

### Form Views

- ``Form``
- ``Label``
- ``Input``
- ``TextArea``
- ``Button``

## Discussion

Typed form attributes are intentionally deferred. Use `.attribute(_:_:)` for valid HTML attributes that do not have dedicated SwiftWebUI modifiers yet.

> Important: Form submission behavior is browser behavior. SwiftWebUI renders markup and resources; it does not provide a server, validation runtime, or request handler.
