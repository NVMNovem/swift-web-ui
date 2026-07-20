# ``SwiftWebUIRuntime``

A deliberately small browser runtime proof of concept for SwiftWebUI.

Use ``mount(_:in:configuration:)`` to lower a concrete SwiftWebUI `View` through `ViewNode` and
the shared renderer-neutral `WebNode` presentation, materialize that presentation
as browser DOM objects, and incrementally reconcile the mounted tree after a `State`
mutation.

The runtime backend mechanically applies every lowered element tag, attribute,
style declaration, fragment, child, and closure action. Container, modifier, and
font semantics remain exclusively in SwiftWebUI's shared lowerer. The runtime
supports one mounted root and positional reconciliation. Text, attributes, styles,
children, node replacements, and closure-action registrations update mechanically;
runtime client-state mutation actions and keyed child moves remain future work.

Use ``SwiftWebUIRuntimeConfiguration`` to opt in to patch logging. Paths in that
output describe the current mounted-tree location and are not stable identity.

## Topics

### Mounting

- ``mount(_:in:configuration:)``
- ``SwiftWebUIRuntimeConfiguration``
