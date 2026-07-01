# Images

Render browser image elements with source and alternative text.

## Overview

Use ``Image`` to render an HTML image:

```swift
Image("assets/profile.jpg", alt: "Profile portrait")
    .width(Length("100%"))
```

## Topics

### Image View

- ``Image``

### Related Styling

- ``Background``
- ``ClipShape``

## Discussion

SwiftWebUI does not manage image files, responsive image sets, or asset bundling. The `source` string is emitted as the image source. Use modifiers such as `.width(_:)`, `.height(_:)`, `.cornerRadius(_:)`, and `.clipShape(_:)` for presentation.
