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

    var body: some View {
        VStack(alignment: .leading, spacing: .px(16)) {
            Text("Hello from Swift")
                .semanticRole(.h1)
                .font(.largeTitle)

            Text(verbatim: "Pressed \(count) times")
                .semanticRole(.p)

            Button("Press") { count += 1 }
                .buttonStyle(.primary)
        }
        .padding(.px(24))
        .navigationTitle("Starter")
    }
}
