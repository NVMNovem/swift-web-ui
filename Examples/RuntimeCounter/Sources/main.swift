//
//  main.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

import SwiftWebUI
import SwiftWebUIRuntime

struct CounterView: View {
    @State private var count = 0
    
    var body: some View {
        VStack(spacing: .px(8)) {
            Text("SwiftWebUI")
                .font(.title)
            Text(String(count))
                .font(.caption)
            HStack {
                Button("Increment") {
                    count += 1
                }
                Button("Increment + 1x") {
                    count += count
                }
                Button("Decrement") {
                    count -= 1
                }
                .background(Color.red)
            }
        }
        .padding(.px(8))
    }
}

@main
struct RuntimeCounterApp {
    static func main() {
        SwiftWebUIRuntime.mount(
            CounterView(),
            in: "app"
        )
    }
}
