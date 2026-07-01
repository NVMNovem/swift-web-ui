# Building a Contact Form

Render semantic browser form markup.

## Overview

SwiftWebUI form primitives stay intentionally small and use generic attributes for form-specific details.

```swift
import SwiftWebUI

struct ContactForm: View {
    var body: some View {
        Form {
            Label("Name")
                .attribute("for", "name")

            Input()
                .id("name")
                .attribute("type", "text")
                .attribute("name", "name")

            Label("Message")
                .attribute("for", "message")

            TextArea()
                .id("message")
                .attribute("name", "message")

            Button("Send")
                .attribute("type", "submit")
                .buttonStyle(.primary)
        }
        .attribute("method", "post")
    }
}
```

## Discussion

SwiftWebUI renders the markup. Submission, validation, and request handling belong to the browser and server application.
