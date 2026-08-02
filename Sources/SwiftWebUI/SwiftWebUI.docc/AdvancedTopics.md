# Advanced Topics

Work with renderer boundaries and future runtime infrastructure.

## Renderer boundary

``ViewRendererProtocol`` has a generic render method and an associated output. Its generic requirement is compatible with Swift 6.3.3 Embedded. A renderer receives a concrete ``View``, obtains ``ViewNode``, and uses the internal Rendering SPI to produce `WebNode`; visitor dispatch does not flow back through the view protocol.

`ViewNodeToWebNodeLowerer` is the only semantic pass. It resolves containers, semantic tags, modifiers, font tokens, controls, canonical attributes/styles, and action intent. The separate static and runtime modules are mechanical `WebNode` consumers.

## State and actions

``State`` uses reference-backed storage, while ``Binding`` retains closure-backed get/set access and optional stable state identity. ``ActionIntent`` carries a closure or concrete state mutation. The shared core does not decide DOM event registration or serialize arbitrary values.

## Runtime work

`SwiftWebUIRuntime` consumes the same `WebNode` as static rendering, attaches closure actions, and positionally reconciles a runtime-only mounted tree. Its next architectural work is explicit keyed `ForEach` identity and state-slot ownership; moves and hydration remain out of scope. Generated JavaScript in the static module is not the runtime renderer.

## Topics

- ``ViewRendererProtocol``
- ``ViewNode``
- ``State``
- ``Binding``
- ``ActionIntent``
- <doc:Architecture>
- <doc:ContributorGuide>
