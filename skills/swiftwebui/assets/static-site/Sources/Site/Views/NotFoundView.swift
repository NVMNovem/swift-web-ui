import SwiftWebUIStatic

struct NotFoundView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: .px(16)) {
            Text("Page not found")
                .semanticRole(.h1)
                .font(.largeTitle)

            Link("Back to the front page", destination: Page.home.path)
        }
    }
}
