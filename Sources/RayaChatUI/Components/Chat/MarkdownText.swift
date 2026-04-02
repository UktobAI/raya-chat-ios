import SwiftUI

/// Renders markdown text using iOS built-in AttributedString.
/// Supports bold, italic, code, links — no third-party library needed.
struct MarkdownText: View {
    let content: String
    let color: Color
    var fontSize: CGFloat = 14

    var body: some View {
        if let attributed = try? AttributedString(markdown: content, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            Text(attributed)
                .font(.system(size: fontSize))
                .foregroundColor(color)
                .lineSpacing(4)
                .tint(color.opacity(0.8)) // Link color
        } else {
            // Fallback to plain text if markdown parsing fails
            Text(content)
                .font(.system(size: fontSize))
                .foregroundColor(color)
                .lineSpacing(4)
        }
    }
}
