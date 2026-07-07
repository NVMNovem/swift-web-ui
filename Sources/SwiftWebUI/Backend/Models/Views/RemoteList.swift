//
//  RemoteList.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 05/07/2026.
//

/// A remote data source for generated SwiftWebUI browser behavior.
public enum RemoteSource: Equatable {
    case get(String)

    var url: String {
        switch self {
        case .get(let url):
            url
        }
    }

    var method: String {
        switch self {
        case .get:
            "GET"
        }
    }
}

/// Fetches a JSON array and renders each item by cloning a named ``Template``.
///
/// `RemoteList` is intentionally small: it emits declarative data attributes and
/// registers a generic runtime script. It does not evaluate Swift data, compile
/// Swift closures to JavaScript, or provide a full reactive client runtime.
public struct RemoteList: View {
    public typealias Body = AnyView

    var source: RemoteSource
    var template: String
    var loadingContent: AnyView
    var emptyContent: AnyView
    var errorContent: AnyView

    public init(source: RemoteSource, template: String) {
        self.source = source
        self.template = template
        self.loadingContent = AnyView(EmptyView())
        self.emptyContent = AnyView(EmptyView())
        self.errorContent = AnyView(EmptyView())
    }

    public init<Loading: View, Empty: View, Error: View>(
        source: RemoteSource,
        template: String,
        loading: Loading,
        empty: Empty,
        error: Error
    ) {
        self.source = source
        self.template = template
        self.loadingContent = AnyView(loading)
        self.emptyContent = AnyView(empty)
        self.errorContent = AnyView(error)
    }

    public func loading<Content: View>(@ViewBuilder content: () -> Content) -> RemoteList {
        var copy = self
        copy.loadingContent = AnyView(content())
        return copy
    }

    public func empty<Content: View>(@ViewBuilder content: () -> Content) -> RemoteList {
        var copy = self
        copy.emptyContent = AnyView(content())
        return copy
    }

    public func error<Content: View>(@ViewBuilder content: () -> Content) -> RemoteList {
        var copy = self
        copy.errorContent = AnyView(content())
        return copy
    }

    public var body: AnyView {
        AnyView(EmptyView())
    }
}
