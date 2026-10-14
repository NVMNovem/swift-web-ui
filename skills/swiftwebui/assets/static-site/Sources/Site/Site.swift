import Foundation

/// Writes the whole site into a directory.
///
///     swift run Site --output dist --resources Resources
///
/// Every `Page` becomes one HTML file, and everything in `Resources/` — the
/// stylesheet, images, fonts, a favicon — is copied beside them unchanged.
@main
struct Site {

    static func main() throws {
        var output = "dist"
        var resources = "Resources"

        var arguments = CommandLine.arguments.dropFirst()
        while let flag = arguments.popFirst() {
            switch (flag, arguments.popFirst()) {
            case ("--output", let value?): output = value
            case ("--resources", let value?): resources = value
            default: throw ArgumentError(description: "unexpected argument \(flag)")
            }
        }

        let files = FileManager.default
        let outputURL = URL(fileURLWithPath: output, isDirectory: true)
        try? files.removeItem(at: outputURL)
        try files.createDirectory(at: outputURL, withIntermediateDirectories: true)

        for page in Page.allCases {
            let file = outputURL.appendingPathComponent(page.outputPath)
            try files.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            try SiteDocument.html(for: page).write(to: file, atomically: true, encoding: .utf8)
        }

        let resourcesURL = URL(fileURLWithPath: resources, isDirectory: true)
        for name in try files.contentsOfDirectory(atPath: resourcesURL.path) where name != ".DS_Store" {
            try files.copyItem(at: resourcesURL.appendingPathComponent(name), to: outputURL.appendingPathComponent(name))
        }

        print("Wrote \(Page.allCases.count) pages to \(output)")
    }
}

private struct ArgumentError: Error, CustomStringConvertible {
    let description: String
}
