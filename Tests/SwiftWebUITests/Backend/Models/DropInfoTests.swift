//
//  DropInfoTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

import Testing
@_spi(Rendering) import SwiftWebUI

@Suite struct DropInfoTests {
    @Test func beforeTheDropOnlyTheKindsOfContentAreKnown() {
        let info = DropInfo(location: Point(x: 4, y: 8), contentTypes: [.plainText, .url])

        #expect(info.location == Point(x: 4, y: 8))
        #expect(info.hasItemsConforming(to: [.url]))
        #expect(info.hasItemsConforming(to: [.text]))
        #expect(!info.hasItemsConforming(to: [.json]))
        #expect(info.itemProviders(for: [.plainText]).isEmpty)
    }

    @Test func aDropOffersOneProviderWithOnlyTheConformingContent() {
        let info = DropInfo(
            location: .zero,
            contentTypes: [.plainText, .html],
            representations: [
                .init(contentType: .plainText, value: "Hello"),
                .init(contentType: .html, value: "<b>Hello</b>"),
            ]
        )

        let providers = info.itemProviders(for: [.plainText])
        #expect(providers.count == 1)
        #expect(providers.first?.registeredContentTypes == [.plainText])
        #expect(info.itemProviders(for: [.json]).isEmpty)
    }
}
