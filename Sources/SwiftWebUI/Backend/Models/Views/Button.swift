//
//  Button.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

public struct Button: View {
    public typealias Body = Never
    enum Label {
        case node(ViewNode)
        case localized(LocalizedResource)
    }

    let labelStorage: Label
    public let action: (() -> Void)?

    /// The lowered label. A localized title is shown here as its default value; it
    /// resolves against the catalog when the control itself is lowered.
    public var label: ViewNode {
        label(in: LocalizationEnvironment())
    }

    func label(in localization: LocalizationEnvironment) -> ViewNode {
        switch labelStorage {
        case .node(let node): node
        case .localized(let resource): Text(resource).makeViewNode(in: ViewContext.detached.localized(localization))
        }
    }

    /// Creates a button whose title is looked up in the localization catalog.
    ///
    /// A string literal or interpolation selects this initializer, as it does for
    /// ``Text``. The title is resolved when the button is lowered, so a
    /// ``View/locale(_:)`` or ``View/localizationCatalog(_:)`` applied anywhere around
    /// the button takes effect.
    public init(_ titleKey: LocalizedResource, action: (() -> Void)? = nil) {
        self.labelStorage = .localized(titleKey)
        self.action = action
    }

    /// Creates a button whose label is a string value, shown without localizing it.
    ///
    /// The label is built in a detached ``ViewContext``, so a `@State` value
    /// declared while producing it does not bind to the mounted root's slot
    /// store and silently falls back to private storage. Declare state on the
    /// enclosing view instead.
    // Disfavored, as in SwiftUI, so that a string literal selects the localized
    // initializer rather than this one.
    @_disfavoredOverload
    public init<S: StringProtocol>(_ label: S, action: (() -> Void)? = nil) {
        self.labelStorage = .node(Text(label).makeViewNode(in: .detached))
        self.action = action
    }

    /// Creates a button whose label is arbitrary content.
    ///
    /// Use this when a control's content is more than a string — an image beside
    /// a name, for instance — so that the whole presentation is the control
    /// rather than a decoy element stretched over it.
    ///
    /// The content closure is evaluated in a detached ``ViewContext``, so a
    /// `@State` value declared inside it does not bind to the mounted root's
    /// slot store and silently falls back to private storage. Declare state on
    /// the enclosing view instead.
    public init<Content: View>(
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.labelStorage = .node(content().makeViewNode(in: .detached))
        self.action = action
    }

    public var body: Never { fatalError("Button primitive body unavailable") }
    public func makeViewNode(in context: ViewContext) -> ViewNode {
        .button(.init(label: label(in: context.localization), action: action.map(ActionIntent.closure)))
    }
}
