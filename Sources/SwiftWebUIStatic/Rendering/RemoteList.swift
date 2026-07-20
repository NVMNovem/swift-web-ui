import SwiftWebUI

public enum RemoteSource: Equatable {
    case get(String)

    var url: String {
        switch self {
        case .get(let url): url
        }
    }

    var method: String {
        switch self {
        case .get: "GET"
        }
    }
}

/// Static-renderer feature that emits remote-list markup and runtime resources.
public struct RemoteList: View {
    public typealias Body = Never

    let source: RemoteSource
    let template: String
    let loadingContent: ViewNode
    let emptyContent: ViewNode
    let errorContent: ViewNode

    public init(source: RemoteSource, template: String) {
        self.source = source
        self.template = template
        self.loadingContent = .empty
        self.emptyContent = .empty
        self.errorContent = .empty
    }

    private init(
        source: RemoteSource,
        template: String,
        loadingContent: ViewNode,
        emptyContent: ViewNode,
        errorContent: ViewNode
    ) {
        self.source = source
        self.template = template
        self.loadingContent = loadingContent
        self.emptyContent = emptyContent
        self.errorContent = errorContent
    }

    public func loading<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> RemoteList {
        RemoteList(
            source: source,
            template: template,
            loadingContent: content().makeViewNode(),
            emptyContent: emptyContent,
            errorContent: errorContent
        )
    }

    public func empty<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> RemoteList {
        RemoteList(
            source: source,
            template: template,
            loadingContent: loadingContent,
            emptyContent: content().makeViewNode(),
            errorContent: errorContent
        )
    }

    public func error<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> RemoteList {
        RemoteList(
            source: source,
            template: template,
            loadingContent: loadingContent,
            emptyContent: emptyContent,
            errorContent: content().makeViewNode()
        )
    }

    public var body: Never {
        fatalError("RemoteList primitive body unavailable")
    }

    public func makeViewNode() -> ViewNode {
        let loading = stateContainer(
            modifiers: [.attribute(name: "data-swiftwebui-remote-loading", value: "true")],
            content: loadingContent
        )
        let empty = stateContainer(
            modifiers: [
                .attribute(name: "data-swiftwebui-remote-empty", value: "true"),
                .attribute(name: "hidden", value: "hidden"),
            ],
            content: emptyContent
        )
        let error = stateContainer(
            modifiers: [
                .attribute(name: "data-swiftwebui-remote-error", value: "true"),
                .attribute(name: "hidden", value: "hidden"),
            ],
            content: errorContent
        )
        let content = stateContainer(
            modifiers: [.attribute(name: "data-swiftwebui-remote-content", value: "true")],
            content: .empty
        )
        let root = ViewNode.container(
            .init(kind: .div, children: [loading, empty, error, content])
        )
        return .modified(
            .init(
                content: root,
                modifiers: [
                    .attribute(name: "data-swiftwebui-remote-list", value: "true"),
                    .attribute(name: "data-swiftwebui-source", value: source.url),
                    .attribute(name: "data-swiftwebui-method", value: source.method),
                    .attribute(name: "data-swiftwebui-template", value: template),
                ]
            )
        )
    }

    private func stateContainer(
        modifiers: [ViewModifierNode],
        content: ViewNode
    ) -> ViewNode {
        .modified(
            .init(
                content: .container(.init(kind: .div, children: content.children)),
                modifiers: modifiers
            )
        )
    }
}

private extension ViewNode {
    var children: [ViewNode] {
        switch self {
        case .empty: []
        case .group(let children): children
        default: [self]
        }
    }
}
