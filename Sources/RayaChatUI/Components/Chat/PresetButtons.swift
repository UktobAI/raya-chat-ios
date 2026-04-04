import SwiftUI

/// Wrapping pill-shaped suggestion buttons, right-aligned.
/// Matches Android FlowRow with Arrangement.End.
struct PresetButtons: View {
    let presets: [String]
    let onPress: (String) -> Void

    @Environment(\.rayaTheme) private var theme
    @State private var containerWidth: CGFloat = 0

    var body: some View {
        if presets.isEmpty { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .trailing, spacing: 8) {
                // Measure available width
                Color.clear.frame(height: 0)
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: WidthKey.self, value: geo.size.width)
                    })
                    .onPreferenceChange(WidthKey.self) { containerWidth = $0 }

                // Render rows
                if containerWidth > 0 {
                    let rows = calculateRows(presets: presets, maxWidth: containerWidth, spacing: 8)
                    ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 8) {
                            ForEach(row, id: \.self) { text in
                                presetPill(text)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 20)
        )
    }

    @ViewBuilder
    private func presetPill(_ text: String) -> some View {
        Button(action: { onPress(text) }) {
            Text(text)
                .font(RayaTypography.buttonSmall)
                .foregroundColor(theme.presetText)
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 50)
                        .stroke(theme.presetBorder, lineWidth: 1)
                )
                .clipShape(Capsule())
        }
    }

    /// Calculate which presets fit on each row (right-aligned wrapping).
    private func calculateRows(presets: [String], maxWidth: CGFloat, spacing: CGFloat) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentWidth: CGFloat = 0

        for text in presets {
            // Estimate pill width: ~8pt per character + 24pt horizontal padding + 2pt border
            let estimatedWidth = CGFloat(text.count) * 8 + 26

            if currentWidth + estimatedWidth + (currentRow.isEmpty ? 0 : spacing) > maxWidth && !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = [text]
                currentWidth = estimatedWidth
            } else {
                currentWidth += estimatedWidth + (currentRow.isEmpty ? 0 : spacing)
                currentRow.append(text)
            }
        }
        if !currentRow.isEmpty { rows.append(currentRow) }

        return rows
    }
}

private struct WidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
