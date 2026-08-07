//
//  ForEach.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

public struct ForEach<Data: Sequence, Content: View>: View {
    public typealias Body = Never
    public let data: Data
    public let content: (Data.Element) -> Content

    /// Derives the identity of one element, or `nil` when the collection is unkeyed.
    let identify: ((Data.Element) -> ViewIdentityToken)?

    /// Creates an unkeyed collection.
    ///
    /// Rows are identified by position, so inserting or removing an element shifts the
    /// state of every row after it. Prefer `init(_:id:content:)` when rows own state.
    public init(
        _ data: Data,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.content = content
        self.identify = nil
    }

    /// Creates a keyed collection.
    ///
    /// Row state follows its element through insertion, removal, and reordering.
    public init<ID: ViewIdentifiable>(
        _ data: Data,
        id: @escaping (Data.Element) -> ID,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.content = content
        self.identify = { id($0).viewIdentityToken }
    }

    public var body: Never { fatalError("ForEach primitive body unavailable") }

    public func makeViewNode(in context: ViewContext) -> ViewNode {
        var nodes: [ViewNode] = []
        for (index, element) in data.enumerated() {
            let elementContext: ViewContext
            if let identify {
                elementContext = context.appending(.identified(identify(element)))
            } else {
                elementContext = context.child(index)
            }
            nodes.append(content(element).makeViewNode(in: elementContext))
        }
        return .group(nodes)
    }
}

public extension ForEach where Data.Element: Identifiable, Data.Element.ID: ViewIdentifiable {
    /// Creates a collection keyed by each element's own identity.
    init(
        _ data: Data,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.init(data, id: { $0.id }, content: content)
    }
}
