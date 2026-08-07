//
//  ConditionalView.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

public enum ConditionalStorage<TrueContent: View, FalseContent: View> {
    case trueContent(TrueContent)
    case falseContent(FalseContent)
}

public struct ConditionalView<TrueContent: View, FalseContent: View>: View {
    public typealias Body = Never
    public let storage: ConditionalStorage<TrueContent, FalseContent>
    public init(storage: ConditionalStorage<TrueContent, FalseContent>) { self.storage = storage }
    public var body: Never { fatalError("ConditionalView primitive body unavailable") }
    public func makeViewNode(in context: ViewContext) -> ViewNode {
        switch storage {
        case .trueContent(let content): content.makeViewNode(in: context.appending(.branch(true)))
        case .falseContent(let content): content.makeViewNode(in: context.appending(.branch(false)))
        }
    }
}
