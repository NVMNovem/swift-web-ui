/// A semantic container for self-contained content.
///
/// `Article` renders an HTML `article` element and is suitable for cards,
/// posts, projects, timeline items, and similar independent content.
public struct Article<Content: View>: View {
    public typealias Body = AnyView

    var content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
