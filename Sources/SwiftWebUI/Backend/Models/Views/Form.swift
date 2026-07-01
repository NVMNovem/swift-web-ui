/// A semantic form container that renders an HTML `form` element.
///
/// Use `.attribute(_:_:)` for form attributes that do not have typed
/// SwiftWebUI modifiers yet.
public struct Form<Content: View>: View {
    public typealias Body = AnyView

    var content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
