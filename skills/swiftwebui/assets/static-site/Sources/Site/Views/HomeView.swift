import SwiftWebUIStatic

struct HomeView: View {

    private struct Feature {
        let title: String
        let summary: String
    }

    private let features = [
        Feature(title: "Written in Swift", summary: "Pages are views; components are structs."),
        Feature(title: "Plain HTML and CSS", summary: "No JavaScript is needed to read a page."),
        Feature(title: "Deploys anywhere", summary: "The build output is a folder of files."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: .px(40)) {
            VStack(alignment: .leading, spacing: .px(16)) {
                Text("A site rendered from Swift")
                    .semanticRole(.h1)
                    .font(.system(size: 44, weight: .bold))
                    .lineHeight(.multiple(1.1))

                Text("Every page here is a SwiftWebUI view, rendered to static HTML at build time.")
                    .semanticRole(.p)
                    .font(.title3)
                    .lineHeight(.multiple(1.5))
                    .foregroundStyle(Theme.secondaryText)
                    .maxWidth(.px(620))

                Link("Read more", destination: Page.about.path)
                    .buttonStyle(.primary)
            }

            Grid(spacing: .px(16)) {
                ForEach(features) { feature in
                    FeatureCard(title: feature.title, summary: feature.summary)
                }
            }
            .gridTemplateColumns("repeat(3, minmax(0, 1fr))")
            // The breakpoint for this grid lives in styles.css.
            .class("site-card-grid")
        }
    }
}

private struct FeatureCard: View {
    let title: String
    let summary: String

    var body: some View {
        Article {
            VStack(alignment: .leading, spacing: .px(8)) {
                Text(title).semanticRole(.h2).font(.headline)
                Text(summary)
                    .semanticRole(.p)
                    .lineHeight(.multiple(1.5))
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(.px(20))
        .background(Theme.surface)
        .border(width: .px(1), color: Theme.border)
        .cornerRadius(.px(14))
    }
}
