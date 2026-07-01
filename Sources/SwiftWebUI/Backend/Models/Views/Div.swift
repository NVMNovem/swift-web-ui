/// A low-level generic container that renders an HTML `div` element.
///
/// Prefer semantic containers or layout views when they express intent.
public struct Div<Content: View>: View {
    public typealias Body = AnyView

    var content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
