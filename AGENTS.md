# AI Architecture Rules

- SwiftHTML owns HTML nodes, attributes, escaping, and rendering.
- SwiftCSS owns CSS properties, values, declarations, and rendering.
- SwiftWebUI owns the web View DSL, modifiers, semantic UI styling, state placeholders, rendered web resources, and WebDocument.
- Do not create custom HTML node systems in SwiftWebUI.
- Do not implement CSS rendering directly in SwiftWebUI.
- Do not reintroduce SwiftWebUI.Border or SwiftWebUI.Shadow thin wrappers.
- Do not create SwiftWeb as a separate package unless explicitly requested.
- Do not create SwiftMailUI or MailDocument yet.
- Future SwiftMailUI must not depend on SwiftWebUI.
- Never implement missing CSS properties, CSS values, or CSS rendering logic in SwiftWebUI. If a required CSS feature is missing from SwiftCSS, stop and clearly report what needs to be added to SwiftCSS first.
