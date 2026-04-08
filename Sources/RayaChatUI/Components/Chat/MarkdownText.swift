import SwiftUI

/// Renders markdown text using iOS built-in AttributedString.
/// Parses once in init — not on every render. Supports bold, italic, code, links.
struct MarkdownText: View {
    let content: String
    let color: Color
    var fontSize: CGFloat = 14

    private let parsed: AttributedString?

    init(content: String, color: Color, fontSize: CGFloat = 14) {
        self.content = content
        self.color = color
        self.fontSize = fontSize
        self.parsed = try? AttributedString(
            markdown: content,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )
    }

    var body: some View {
        Text(parsed ?? AttributedString(content))
            .font(.system(size: fontSize))
            .foregroundColor(color)
            .lineSpacing(4)
            .tint(color.opacity(0.8))
    }
}
