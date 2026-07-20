import SwiftWebUI

struct CounterView: View {
    @State private var count = 0

    var body: some View {
        VStack {
            Text("Count")

            if count == 0 {
                Text("Zero")
            } else {
                Text("Non-zero")
            }

            Button("Increment") {
                count += 1
            }
        }
        .padding(.px(8))
    }
}

@main
struct SwiftWebUIEmbeddedDemo {
    static func main() {
        _ = CounterView().makeViewNode()
        _ = ForEach(["One", "Two"]) { item in
            Text(item)
        }.makeViewNode()
    }
}
