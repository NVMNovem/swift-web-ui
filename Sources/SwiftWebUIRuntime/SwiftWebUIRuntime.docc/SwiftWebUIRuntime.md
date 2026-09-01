# ``SwiftWebUIRuntime``

A deliberately small browser runtime proof of concept for SwiftWebUI.

Use ``mount(_:in:configuration:)`` to lower a concrete SwiftWebUI `View` through `ViewNode` and
the shared renderer-neutral `WebNode` presentation, materialize that presentation
as browser DOM objects, and incrementally reconcile the mounted tree after a `State`
mutation.

A view's ``SwiftWebUI/View/navigationTitle(_:)`` is document metadata rather
than body DOM. The mounted root applies it to `document.title`, updates it after
state-driven rebuilds, and restores the title that existed before mounting when
the view stops supplying a title or the root is stopped.

The runtime backend mechanically applies every lowered element tag, attribute,
style declaration, fragment, child, and closure action. Container, modifier, and
font semantics remain exclusively in SwiftWebUI's shared lowerer. The runtime
supports one mounted root and positional reconciliation. Text, attributes, styles,
children, node replacements, and closure-action registrations update mechanically;
runtime client-state mutation actions and keyed child moves remain future work.

Use ``mount(_:in:resources:configuration:)`` with ``RuntimeResources`` to install
application stylesheets before the initial DOM tree. External URLs are resolved by
the browser relative to the served document; inline CSS is preserved in a `style`
element. Stylesheets are retained by the current single mounted application root and
are not recreated by reconciliation. Asset files remain an application packaging
concern and must be copied beneath the served output root by the build workflow.

The runtime installs its own stylesheet ahead of every application stylesheet.
It currently carries one rule, for the dialog `::backdrop` — a pseudo-element,
and so the one piece of dialog presentation that cannot be an inline element
declaration. It is coloured through the `--swiftwebui-dialog-backdrop` custom
property, and an application stylesheet installed after it can override the rule
outright.

The runtime also owns the document body's scroll lock, so that the page behind
something presented over it stops scrolling. This is not a modifier and has no
public spelling: it is a counter held by the single mounted root, taken by the
presentation primitive and released by it. Two presented things share the one
counter, so the body stops scrolling on the first acquire and starts again only
on the last release, restoring whatever inline `overflow` it found rather than
assuming there was none. A counter any caller could increment is a counter that
ends up unbalanced, and the symptom is a page that can never scroll again.

The runtime schedules enter and exit transitions. An entering element gets its
enter class on the frame after insertion; a leaving one keeps its DOM node, under
its old parent and wearing its exit class, for the declared duration. That node is
already out of the mounted tree, so positional paths are unaffected and a later
render mounts a fresh node rather than reclaiming the leaving one. Pending frames
and timers are cancelled when the root is stopped or remounted, because work that
outlives its subtree would try to remove a node that is no longer a child of
anything. A reader who prefers reduced motion skips both the animation and the
wait.

Use ``SwiftWebUIRuntimeConfiguration`` to opt in to patch logging. Paths in that
output describe the current mounted-tree location and are not stable identity.

## Topics

### Mounting

- ``mount(_:in:configuration:)``
- ``mount(_:in:resources:configuration:)``
- ``SwiftWebUIRuntimeConfiguration``

### Application resources

- <doc:RuntimeApplicationResources>
- ``RuntimeResources``
- ``RuntimeStylesheet``
