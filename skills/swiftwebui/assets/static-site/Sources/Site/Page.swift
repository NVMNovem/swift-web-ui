/// Every page the site has, and where each one lives.
///
/// Adding a page is adding a case here and a view for it in `PageView`.
enum Page: String, CaseIterable, Sendable {
    case home
    case about
    case notFound

    /// The address, with no trailing slash.
    var path: String {
        switch self {
        case .home: "/"
        case .about: "/about"
        case .notFound: "/404"
        }
    }

    /// Where the file is written under `dist/`.
    ///
    /// `about/index.html` rather than `about.html`: static hosts and
    /// `python3 -m http.server` both serve that at `/about` unconfigured.
    var outputPath: String {
        switch self {
        case .home: "index.html"
        case .notFound: "404.html"
        default: String(path.dropFirst()) + "/index.html"
        }
    }

    var title: String {
        switch self {
        case .home: "Site"
        case .about: "About"
        case .notFound: "Page not found"
        }
    }

    /// The `<meta name="description">`, one sentence.
    var summary: String {
        switch self {
        case .home: "A site rendered to static HTML from Swift."
        case .about: "What this site is and who makes it."
        case .notFound: "This page does not exist."
        }
    }
}
