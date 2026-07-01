# Architecture

Understand the ownership boundaries between SwiftWebUI, SwiftCSS, and SwiftHTML.

## Overview

SwiftWebUI is the browser UI layer in a layered Swift web ecosystem.

```text
SwiftWebUI
    View DSL, modifiers, semantic UI styling, state placeholders,
    rendered web resources, WebDocument

SwiftCSS
    CSS properties, values, declarations, stylesheet rendering

SwiftHTML
    HTML nodes, attributes, escaping, HTML rendering
```

The dependency direction is:

```text
User View
    -> SwiftWebUI
        -> SwiftCSS
        -> SwiftHTML
```

## Topics

### SwiftWebUI Ownership

- ``View``
- ``ViewBuilder``
- ``ModifiedView``
- ``HTMLRenderer``
- ``RenderedView``
- ``WebDocument``

### Rendering Resources

- ``RenderContext``
- ``RenderedResources``
- ``StyleResource``
- ``ScriptResource``
- ``ResourceScope``

## Discussion

SwiftWebUI must not duplicate low-level HTML or CSS systems. If a feature is a new HTML element, attribute rendering rule, escaping rule, CSS property, CSS value, declaration, or stylesheet rendering behavior, it belongs in SwiftHTML or SwiftCSS first.

SwiftWebUI owns the higher-level web UI intent: primitive view types such as
``Text``, ``VStack``, ``Grid``, ``Button``, ``Link``, ``Image``, ``Article``,
``Section``, ``Form``, ``Label``, ``Input``, ``TextArea``, and ``Footer``;
view modifiers stored as data; semantic UI styling such as ``ButtonStyle`` and
``ButtonStyleToken``; state placeholders such as ``State`` and ``Binding``;
rendered resource collection; and ``WebDocument`` as a browser document target.

SwiftWebUI must not reimplement CSS properties, CSS values, CSS rendering,
HTML elements, HTML attributes, or HTML escaping. Those concerns belong to
SwiftCSS and SwiftHTML.

> Important: Do not reintroduce `SwiftWebUI.Border` or `SwiftWebUI.Shadow` as thin wrappers. Use SwiftCSS `Border` and `BoxShadow`, or add missing capabilities to SwiftCSS first.

Future packages such as SwiftMailUI should follow the same rule. A future SwiftMailUI package may depend on SwiftHTML and SwiftCSS, but it must not depend on SwiftWebUI.
