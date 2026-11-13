//
//  StarterApp.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

import SwiftWebUI
import SwiftWebUIRuntime

@main
struct StarterApp: App {
    var body: some Scene {
        Page {
            Counter()
        }
        .stylesheet(.external("styles.css"))
    }
}

struct Counter: View {
    @State private var count = 0
    @State private var greeting = "Hello"

    var body: some View {
        VStack(alignment: .leading, spacing: .px(16)) {
            Text(verbatim: greeting + " from Swift")
                .semanticRole(.h1)
                .font(.largeTitle)

            Text(verbatim: "Pressed \(count) times")
                .semanticRole(.p)

            Button("Press") { count += 1 }
                .buttonStyle(.primary)
        }
        .modifier(Card())
        .navigationTitle("Starter")
        // Work a view starts itself, once it is on the page.
        .task {
            greeting = await loadGreeting()
        }
    }
}

/// A modifier the application packages for itself.
struct Card: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(.px(24))
    }
}

/// Stands in for a network request.
func loadGreeting() async -> String {
    "Hello"
}
