import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Wrapping pill-shaped suggestion buttons, right-aligned.
/// Pills sit on the same row when they fit, wrap to next row when they don't.
struct PresetButtons: View {
    let presets: [String]
    let onPress: (String) -> Void

    @Environment(\.rayaTheme) private var theme
    @State private var containerWidth: CGFloat = 0

    var body: some View {
        if presets.isEmpty { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .trailing, spacing: 8) {
                // Measure container width
                Color.clear.frame(height: 0)
                    .background(GeometryReader { geo in
                        Color.clear.preference(key: WidthKey.self, value: geo.size.width)
                    })
                    .onPreferenceChange(WidthKey.self) { containerWidth = $0 }

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
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 50)
                        .stroke(theme.presetBorder, lineWidth: 1)
                )
                .clipShape(Capsule())
        }
    }

    /// Calculate rows using actual text measurement — not character estimation.
    private func calculateRows(presets: [String], maxWidth: CGFloat, spacing: CGFloat) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentWidth: CGFloat = 0

        for text in presets {
            let pillWidth = measurePillWidth(text)

            if currentWidth + pillWidth + (currentRow.isEmpty ? 0 : spacing) > maxWidth && !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = [text]
                currentWidth = pillWidth
            } else {
                currentWidth += pillWidth + (currentRow.isEmpty ? 0 : spacing)
                currentRow.append(text)
            }
        }
        if !currentRow.isEmpty { rows.append(currentRow) }
        return rows
    }

    /// Measure actual pill width using UIFont metrics.
    private func measurePillWidth(_ text: String) -> CGFloat {
        #if canImport(UIKit)
        let font = UIFont.systemFont(ofSize: 13, weight: .medium) // matches RayaTypography.buttonSmall
        let textWidth = (text as NSString).size(withAttributes: [.font: font]).width
        return textWidth + 24 + 2 // 12pt padding each side + border
        #else
        return CGFloat(text.count) * 8 + 26
        #endif
    }
}

private struct WidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
