/// A declarative SwiftWebUI component.
public protocol View {
    associatedtype Body: View

    @ViewBuilder var body: Body { get }

    /// Lowers the view to renderer-neutral semantic data.
    func makeViewNode() -> ViewNode
}

public extension View {
    func makeViewNode() -> ViewNode {
        body.makeViewNode()
    }
}

extension Never: View {
    public typealias Body = Never

    public var body: Never {
        fatalError("Never has no body")
    }

    public func makeViewNode() -> ViewNode {
        fatalError("Never cannot be lowered")
    }
}

/// A renderer with a statically specialized SwiftWebUI entry point.
public protocol ViewRendererProtocol {
    associatedtype Output

    func render<Content: View>(_ view: Content) -> Output
}
