public struct Label<Content: View>: View {
    public typealias Body = AnyView

    var textLabel: String?
    var content: Content

    public init(_ textLabel: String) where Content == EmptyView {
        self.textLabel = textLabel
        self.content = EmptyView()
    }

    public init(@ViewBuilder content: () -> Content) {
        self.textLabel = nil
        self.content = content()
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
