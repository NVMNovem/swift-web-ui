import SwiftWebUI

struct RootView: View {
    @State private var count = 0
    @State private var isAboutPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: .px(24)) {
            Text("Counter")
                .semanticRole(.h1)
                .font(.largeTitle)

            Text("Count: \(count)")
                .semanticRole(.p)
                .font(.title2)

            HStack(spacing: .px(12)) {
                Button("Decrease") { count -= 1 }
                    .buttonStyle(.secondary)
                Button("Increase") { count += 1 }
                    .buttonStyle(.primary)
            }

            Button("About") { isAboutPresented = true }
                .sheet(isPresented: $isAboutPresented) {
                    VStack(alignment: .leading, spacing: .px(16)) {
                        Text("About").semanticRole(.h2).font(.title2)
                        Text("Swift, running in the browser.").semanticRole(.p)
                        Button("Close") { isAboutPresented = false }
                            .buttonStyle(.primary)
                    }
                    .padding(.px(24))
                }
        }
        .padding(.px(32))
        .maxWidth(.px(640))
        .margin(.horizontal, .auto)
        // State-derived, so the tab title follows the count.
        .navigationTitle("Counter (\(count))")
    }
}
