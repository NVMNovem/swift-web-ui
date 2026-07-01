/// A semantic footer container that renders an HTML `footer` element.
public struct Footer<Content: View>: View {
    public typealias Body = AnyView

    var content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
