import Testing
import SwiftWebUI

@Test func swiftCSSValuesAreAvailableThroughSwiftWebUIImport() {
    let rendered = HTMLRenderer().renderView(
        Text("Hello")
            .font(.system(size: 19, weight: .heavy))
            .width(.px(100))
            .background(Color("var(--panel)"))
            .foregroundStyle(Color("var(--muted)"))
            .border(width: .px(1), color: Color("var(--border)"))
            .letterSpacing(.em(0.1))
            .lineHeight(.em(1.5))
    )
    let css = rendered.cssString()

    #expect(css.contains("font-size: 19px"))
    #expect(css.contains("font-weight: 800"))
    #expect(css.contains("width: 100px"))
    #expect(css.contains("background-color: var(--panel)"))
    #expect(css.contains("color: var(--muted)"))
    #expect(css.contains("border: 1px solid var(--border)"))
    #expect(css.contains("letter-spacing: 0.1em"))
    #expect(css.contains("line-height: 1.5em"))
}

