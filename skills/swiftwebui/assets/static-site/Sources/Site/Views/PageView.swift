import SwiftWebUIStatic

/// The one view rendered per page: the shared layout around that page's content.
struct PageView: View {
    let page: Page

    var body: some View {
        SiteLayout {
            // Each branch is a different concrete type, which a `switch` in a
            // view builder carries without type erasure.
            switch page {
            case .home: HomeView()
            case .about: AboutView()
            case .notFound: NotFoundView()
            }
        }
    }
}
