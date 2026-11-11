//
//  AppTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

import Testing
import SwiftWebUI
@testable import SwiftWebUIRuntime

@Suite struct AppTests {
    private struct Greeting: View {
        var body: some View { Text(verbatim: "Hello") }
    }

    private struct DefaultApp: App {
        var body: some Scene {
            Page { Greeting() }
        }
    }

    private struct ConfiguredApp: App {
        var body: some Scene {
            Page { Greeting() }
                .stylesheet(.external("styles.css"))
                .stylesheet(.inline("body { margin: 0 }"))
                .mountPoint("root")
                .reconciliationLogging()
        }
    }

    @Test func aPageMountsIntoAppWithNoResourcesByDefault() {
        let page = Page { Greeting() }

        #expect(page.mountPoint == "app")
        #expect(page.resources == RuntimeResources())
        #expect(page.configuration.reconciliationLogging == false)
    }

    @Test func stylesheetsAreKeptInTheOrderTheyWereAdded() {
        let page = Page { Greeting() }
            .stylesheet(.external("styles.css"))
            .stylesheet(.inline("body { margin: 0 }"))

        #expect(page.resources.stylesheets == [
            .external("styles.css"),
            .inline("body { margin: 0 }"),
        ])
    }

    @Test func modifiersLeaveTheOriginalPageUntouched() {
        let original = Page { Greeting() }
        let changed = original.mountPoint("root").reconciliationLogging()

        #expect(original.mountPoint == "app")
        #expect(original.configuration.reconciliationLogging == false)
        #expect(changed.mountPoint == "root")
        #expect(changed.configuration.reconciliationLogging)
    }

    @Test func anAppDescribesItsSceneWithoutABrowser() {
        // `some Scene` hides the page, so the concrete type is named to read it back.
        func page<A: App>(of app: A) -> A.Body { app.body }

        let scene: Page<Greeting> = page(of: ConfiguredApp()) as! Page<Greeting>

        #expect(scene.mountPoint == "root")
        #expect(scene.resources.stylesheets.count == 2)
        #expect(scene.configuration.reconciliationLogging)
        _ = page(of: DefaultApp())
    }
}
