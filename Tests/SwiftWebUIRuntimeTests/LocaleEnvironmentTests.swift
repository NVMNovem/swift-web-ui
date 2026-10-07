//
//  LocaleEnvironmentTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 07/10/2026.
//

import Testing
@_spi(Runtime) @_spi(Rendering) import SwiftWebUI
@testable import SwiftWebUIRuntime

// MARK: - Fixtures

private let catalog = LocalizationCatalog(sourceLanguage: "en", entries: [
    "cart.title": .init(localizations: [
        "en": .init(variation: .string("Cart")),
        "nl": .init(variation: .string("Winkelwagen")),
    ]),
])

/// Reads the locale in its `body`, beside a text that resolves in it.
private struct LocaleLabel: View {
    @Environment(LocaleIdentifier.self) private var locale

    var body: some View {
        Text(verbatim: "locale=\(locale.identifier)")
    }
}

/// Reads the locale only inside an action.
private struct LocaleButton: View {
    @Environment(LocaleIdentifier.self) private var locale
    let record: (LocaleIdentifier) -> Void

    var body: some View {
        Button("Order") { record(locale) }
    }
}

private final class Recorder {
    var locales: [LocaleIdentifier] = []
}

// MARK: - Helpers

private func texts(_ node: FakeDOMNode) -> [String] {
    var found: [String] = []
    if let text = node.text { found.append(text) }
    for child in node.children { found.append(contentsOf: texts(child)) }
    return found
}

private func buttons(_ node: FakeDOMNode) -> [FakeDOMNode] {
    var found: [FakeDOMNode] = []
    if node.action != nil { found.append(node) }
    for child in node.children { found.append(contentsOf: buttons(child)) }
    return found
}

private func rendered<Content: View>(_ view: @escaping () -> Content) -> FakeDOMBackend {
    let backend = FakeDOMBackend()
    let root = MountedRoot(container: backend.root, backend: backend) {
        ViewNodeToWebNodeLowerer().lowerView(view().makeViewNode())
    }
    root.start()
    root.stop()
    return backend
}

// MARK: - Tests

// The readable locale lives in the environment storage, which is shared, so these run in
// the serialized suite like the other environment tests.
extension RuntimeMountTests {
    @Suite struct LocaleEnvironmentTests {

        @Test func aViewReadsTheLocaleInEffect() {
            #expect(texts(rendered { LocaleLabel().locale("nl-BE") }.root) == ["locale=nl-BE"])
            // Normalized like every locale identifier.
            #expect(texts(rendered { LocaleLabel().locale("zh_hant_tw") }.root) == ["locale=zh-Hant-TW"])
        }

        @Test func theReadFallsBackLikeTextDoes() {
            // Nothing placed: undetermined, never a failure.
            #expect(texts(rendered { LocaleLabel() }.root) == ["locale=und"])
            // A catalog without a locale: its source language, which is what text resolves in.
            #expect(texts(rendered { LocaleLabel().localizationCatalog(catalog) }.root) == ["locale=en"])
            #expect(texts(rendered { LocaleLabel().localizationCatalog(catalog).locale("fr") }.root) == ["locale=fr"])
            #expect(texts(rendered { LocaleLabel().locale("fr").localizationCatalog(catalog) }.root) == ["locale=fr"])
        }

        @Test func theReadAgreesWithTheTextBesideIt() {
            let backend = rendered {
                VStack {
                    LocaleLabel()
                    Text("cart.title")
                }
                .localizationCatalog(catalog)
                .locale("nl")
            }
            #expect(texts(backend.root) == ["locale=nl", "Winkelwagen"])
        }

        @Test func aNearerLocaleIsReadForItsSubtreeOnly() {
            let backend = rendered {
                VStack {
                    LocaleLabel()
                    LocaleLabel().locale("fr")
                    LocaleLabel()
                }
                .locale("nl")
            }
            #expect(texts(backend.root) == ["locale=nl", "locale=fr", "locale=nl"])
        }

        @Test func nothingLeaksOutOfATraversal() {
            _ = rendered { LocaleLabel().locale("nl") }
            #expect(texts(rendered { LocaleLabel() }.root) == ["locale=und"])
        }

        @Test func anActionReadsTheLocaleAfterTheTraversal() {
            let recorder = Recorder()
            let backend = FakeDOMBackend()
            let root = MountedRoot(container: backend.root, backend: backend) {
                ViewNodeToWebNodeLowerer().lowerView(
                    VStack {
                        LocaleButton { recorder.locales.append($0) }
                        LocaleButton { recorder.locales.append($0) }.locale("fr")
                    }
                    .locale("nl")
                    .makeViewNode()
                )
            }
            defer { root.stop() }
            root.start()

            for button in buttons(backend.root) { button.action?() }
            #expect(recorder.locales == ["nl", "fr"])
        }
    }
}
