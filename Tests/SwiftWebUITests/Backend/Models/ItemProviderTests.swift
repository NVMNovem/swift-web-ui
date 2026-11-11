//
//  ItemProviderTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

import Testing
@_spi(Rendering) import SwiftWebUI

@Suite struct ItemProviderTests {
    @Test func anObjectIsCarriedAsPlainText() {
        let provider = ItemProvider(object: "card-1")
        #expect(provider.registeredTypeIdentifiers == ["text/plain"])
        #expect(provider.registeredContentTypes == [.plainText])
        #expect(provider.canLoadObject(ofClass: String.self))

        var loaded: String?
        provider.loadObject(ofClass: String.self) { loaded = $0 }
        #expect(loaded == "card-1")
    }

    @Test func itemsAreKeptPerTypeAndTheLatestRegistrationWins() {
        let provider = ItemProvider(item: "{}", typeIdentifier: UTType.json.identifier)
        provider.registerObject("first")
        provider.registerObject("second")
        provider.registerItem("ignored", forTypeIdentifier: "not a mime type")

        #expect(provider.registeredTypeIdentifiers == ["application/json", "text/plain"])
        #expect(provider.hasItemConformingToTypeIdentifier("application/json"))
        #expect(!provider.hasItemConformingToTypeIdentifier("text/html"))

        var json: String?
        provider.loadItem(forTypeIdentifier: "application/json") { json = $0 }
        #expect(json == "{}")

        var text: String?
        provider.loadObject(ofClass: String.self) { text = $0 }
        #expect(text == "second")
    }

    @Test func loadingSomethingItDoesNotCarryYieldsNil() {
        let provider = ItemProvider(item: "{}", typeIdentifier: "application/json")
        #expect(!provider.canLoadObject(ofClass: String.self))

        var loaded: String? = "unchanged"
        provider.loadItem(forTypeIdentifier: "text/html") { loaded = $0 }
        #expect(loaded == nil)
    }
}
