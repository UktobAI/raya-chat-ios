import SwiftUI

/// Suggestion buttons — right-aligned wrapping pills.
struct PresetButtons: View {
    let presets: [String]
    let onPress: (String) -> Void

    @Environment(\.rayaTheme) private var theme

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(presets, id: \.self) { text in
                Button(action: { onPress(text) }) {
                    Text(text)
                        .font(RayaTypography.buttonSmall)
                        .foregroundColor(theme.presetText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(theme.presetBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 50)
                                .stroke(theme.presetBorder, lineWidth: 1)
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 12)
        .padding(.bottom, 20)
    }
}

/// Simple flow layout for wrapping content.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}
