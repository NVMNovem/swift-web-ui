//
//  ButtonStyle.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

/// A static style description for SwiftWebUI buttons.
///
/// Button styles are evaluated during rendering to collect supported modifier
/// data. They do not receive live browser interaction state.
public protocol ButtonStyle {
    associatedtype Body: View

    typealias Configuration = ButtonStyleConfiguration

    func makeBody(configuration: Configuration) -> Body
}

/// Inputs passed to a ``ButtonStyle``.
public struct ButtonStyleConfiguration {
    
    public let label: Label
    public let isPressed: Bool
    public let isHovered: Bool
    public let isFocused: Bool

    public init(
        label: Label = Label(),
        isPressed: Bool = false,
        isHovered: Bool = false,
        isFocused: Bool = false
    ) {
        self.label = label
        self.isPressed = isPressed
        self.isHovered = isHovered
        self.isFocused = isFocused
    }

    public struct Label: View {
        public typealias Body = AnyView

        public init() {}

        public var body: AnyView {
            AnyView(EmptyView())
        }
    }
}

/// Type-erased storage for a ``ButtonStyle``.
public struct AnyButtonStyle {
    
    private let makeModifiers: () -> [ViewModifierData]

    init<S: ButtonStyle>(_ style: S) {
        makeModifiers = {
            let body = style.makeBody(configuration: ButtonStyleConfiguration())
            return staticButtonStyleModifiers(from: body)
        }
    }

    func modifiers() -> [ViewModifierData] {
        makeModifiers()
    }
}

protocol StaticButtonStyleModifierSource {
    var staticButtonStyleModifiers: [ViewModifierData]? { get }
}

extension ButtonStyleConfiguration.Label: StaticButtonStyleModifierSource {
    var staticButtonStyleModifiers: [ViewModifierData]? {
        []
    }
}

extension ModifiedView: StaticButtonStyleModifierSource {
    
    var staticButtonStyleModifiers: [ViewModifierData]? {
        guard
            let source = content as? any StaticButtonStyleModifierSource,
            let contentModifiers = source.staticButtonStyleModifiers
        else {
            return nil
        }

        return contentModifiers + modifiers
    }
}

private func staticButtonStyleModifiers<V: View>(from view: V) -> [ViewModifierData] {
    guard
        let source = view as? any StaticButtonStyleModifierSource,
        let modifiers = source.staticButtonStyleModifiers
    else {
        return []
    }

    return modifiers
}
