/// A void form input that renders an HTML `input` element.
///
/// Configure type, name, autocomplete, and related attributes with
/// `.attribute(_:_:)`.
public struct Input: View {
    public typealias Body = AnyView

    public init() {}

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
