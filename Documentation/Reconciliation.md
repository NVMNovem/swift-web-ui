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

## Keyed diff

A `ForEach` created with `id:` (or over `Identifiable` elements) lowers each row to
`WebNode.keyed(key, node)`. The key is the explicit identity the caller supplied, never
derived from content. A keyed node mounts as a one-child fragment carrying its key, so
no wrapper element reaches the DOM and a path through it is addressed like any other:
the row's own node is child 0.

When either side of a children list holds a keyed child, the differ matches children by
identity instead of by position. A keyed child matches the child with the same key; an
unkeyed child matches the unkeyed child with the same ordinal among its unkeyed siblings,
so a header next to a list stays where it is. A repeated key among siblings cannot be
matched, so that list falls back to positional diffing.

Structure is patched before content: unmatched old children are removed (highest index
first), then each position is filled left to right by `moveChild` of an existing child or
`insertChild` of a new one, and only then are surviving children diffed at their final
index. A move re-inserts the child's DOM nodes, which keeps the elements, their
registrations and their state; a browser may drop focus from a node that is moved while
focused. Moves are not minimal: they are one per child that is not already in place when
the walk reaches it.

## Current limits

This slice intentionally has no transitions between moves, animations, hydration, multiple
mounted roots, component lifecycle callbacks, or fine-grained state dependency tracking. Every
state write rebuilds and re-diffs the whole root; writes are not coalesced. Position
must not be treated as permanent semantic identity, and identity must never be inferred
from text, tags, rendered hashes, or content hashes.

View identity for *state* is already keyed, and is a separate concern from this
positional DOM differ: `ViewIdentityPath` is built during lowering and decides which
`@State` box a rebuilt view resolves to. See <doc:StateAndBindings>.

Keyed repeated content flows like this:

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
it now does, as described under Keyed diff.
