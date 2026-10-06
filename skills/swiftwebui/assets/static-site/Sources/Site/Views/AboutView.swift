import SwiftWebUIStatic

struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: .px(16)) {
            Text("About")
                .semanticRole(.h1)
                .font(.largeTitle)

            Text("Replace this page with your own.")
                .semanticRole(.p)
                .lineHeight(.multiple(1.6))
        }
        .maxWidth(.px(680))
    }
}
