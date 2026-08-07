# Runtime DOM reconciliation

`SwiftWebUIRuntime` retains a runtime-only tree that connects the last lowered
`WebNode` presentation to the browser nodes created for it:

```text
State mutation
      ↓
new ViewNode → new WebNode
      ↓
WebNodeDiffer(old, new)
      ↓
DOMPatch[]
      ↓
DOMPatchApplier
      ↓
MountedNode + browser DOM
```

Initial mounting recursively creates the complete DOM and returns a `MountedNode`.
Mounted text nodes retain a DOM handle and current value. Mounted elements retain
their handle, tag, attributes, styles, positional children, and optional action
registration. Mounted fragments retain positional children without introducing a
browser wrapper. Removing or replacing a mounted subtree recursively releases all
action registrations in that subtree.

`WebNode` remains renderer-neutral. DOM handles, JavaScriptKit values, action
registrations, paths, and reconciliation state exist only in `SwiftWebUIRuntime`.
Static rendering is unaffected.

## Positional diff

`NodePath` is a location in the current mounted tree, not semantic identity. The
differ compares equal node cases, updates text directly, compares attributes and
styles by name, and diffs element or fragment children by position. Added trailing
children are inserted in ascending order; removed trailing children are removed in
descending order. Node-case and element-tag changes replace only that node.

Patch ordering is deterministic: removed attributes, set attributes, removed
styles, set styles, action replacement, shared child diffs, then trailing child
insertions or removals. Within named values, old order controls removals and new
order controls additions and changes.

Closure actions do not currently carry a renderer-neutral identity token. An
action-bearing element therefore keeps its DOM node but conservatively replaces its
event registration on rerender. `setState` action intents compare their stable
mutation value. Reflection and closure identity inspection are never used.

Opt in to patch diagnostics at the mount point:

```swift
SwiftWebUIRuntime.mount(
    CounterView(),
    in: "app",
    configuration: .init(reconciliationLogging: true)
)
```

Logging is disabled by default. An invariant failure in patch application emits an
explicit `reconciliation fallback` message before the temporary full-root recovery;
ordinary text, attribute, style, action, insertion, removal, and replacement patches
never use that fallback.

## Current limits

This slice intentionally has no DOM-level moves, middle insertion with preserved
sibling identity, list reordering, transitions, animations, hydration, multiple mounted
roots, component lifecycle callbacks, or fine-grained state dependency tracking. Every
state write rebuilds and re-diffs the whole root; writes are not coalesced. Position
must not be treated as permanent semantic identity, and identity must never be inferred
from text, tags, rendered hashes, or content hashes.

View identity for *state* is already keyed, and is a separate concern from this
positional DOM differ: `ViewIdentityPath` is built during lowering and decides which
`@State` box a rebuilt view resolves to. See <doc:StateAndBindings>.

The next reconciliation step is explicitly keyed repeated content:

```text
ForEach element ID
      ↓
stable WebIdentity
      ↓
keyed mounted child map
      ↓
insert / remove / move
      ↓
state preserved across reordering
```

That work requires user or domain identity to flow through the shared presentation;
it is not implemented by this positional reconciler.
