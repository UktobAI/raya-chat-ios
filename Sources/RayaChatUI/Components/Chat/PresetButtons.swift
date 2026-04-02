import SwiftUI

/// Suggestion buttons — right-aligned wrapping pills.
struct PresetButtons: View {
    let presets: [String]
    let onPress: (String) -> Void

    @Environment(\.rayaTheme) private var theme

    var body: some View {
        WrappingHStack(spacing: 8, alignment: .trailing) {
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
        .padding(.horizontal, 12)
        .padding(.bottom, 20)
    }
}

/// iOS 15-compatible wrapping HStack using preference keys.
/// Replaces `Layout` protocol (iOS 16+) for backward compatibility.
struct WrappingHStack: View {
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: () -> [AnyView]

    @State private var totalHeight: CGFloat = 0

    init<Data: RandomAccessCollection, Content: View>(
        spacing: CGFloat = 8,
        alignment: HorizontalAlignment = .leading,
        @ViewBuilder content: () -> ForEach<Data, Data.Element, Content>
    ) where Data.Element: Hashable {
        self.spacing = spacing
        self.alignment = alignment
        let forEach = content()
        self.content = { forEach.data.map { item in AnyView(forEach.content(item)) } }
    }

    var body: some View {
        GeometryReader { geo in
            generateContent(in: geo.size.width)
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in availableWidth: CGFloat) -> some View {
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        let items = content()

        return ZStack(alignment: .topLeading) {
            // Invisible sizing pass — measures each item
            Color.clear
                .frame(height: 0)

            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                item
                    .alignmentGuide(.leading) { dim in
                        if abs(x - dim.width) > availableWidth {
                            x = 0
                            y -= rowHeight + spacing
                            rowHeight = 0
                        }
                        rowHeight = max(rowHeight, dim.height)
                        let result = x
                        if index == items.count - 1 {
                            x = 0 // reset
                        } else {
                            x -= dim.width + spacing
                        }
                        return -result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = y
                        if index == items.count - 1 {
                            y = 0 // reset
                        }
                        return -result
                    }
            }
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: HeightPrefKey.self, value: geo.size.height)
            }
        )
        .onPreferenceChange(HeightPrefKey.self) { height in
            totalHeight = height
        }
        .frame(maxWidth: .infinity, alignment: alignment == .trailing ? .trailing : .leading)
    }
}

private struct HeightPrefKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
