//
//  UTTypeTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

import Testing
import SwiftWebUI

@Suite struct UTTypeTests {
    @Test func identifierIsTheMIMEType() {
        #expect(UTType.plainText.identifier == "text/plain")
        #expect(UTType.url.identifier == "text/uri-list")
        #expect(UTType.html.identifier == "text/html")
        #expect(UTType.json.identifier == "application/json")
        #expect(UTType.json.preferredMIMEType == "application/json")
    }

    @Test func aMIMETypeIsNormalizedAndAnythingElseIsRefused() {
        #expect(UTType(mimeType: " Application/JSON ") == .json)
        #expect(UTType(mimeType: "Files") == nil)
        #expect(UTType(mimeType: "") == nil)
    }

    @Test func conformanceIgnoresParametersAndFollowsAbstractTypes() {
        let utf8 = UTType(mimeType: "text/plain;charset=utf-8")
        #expect(utf8?.conforms(to: .plainText) == true)
        #expect(UTType.html.conforms(to: .text))
        #expect(UTType.json.conforms(to: .item))
        #expect(!UTType.json.conforms(to: .text))
        #expect(!UTType.plainText.conforms(to: .html))
        #expect(!UTType.text.conforms(to: .plainText))
    }
}
