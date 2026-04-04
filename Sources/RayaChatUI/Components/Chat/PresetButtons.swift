import SwiftUI

/// Suggestion buttons — right-aligned wrapping pills. Matches Android PresetButtons.
struct PresetButtons: View {
    let presets: [String]
    let onPress: (String) -> Void

    @Environment(\.rayaTheme) private var theme

    var body: some View {
        if presets.isEmpty { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .trailing, spacing: 8) {
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
        )
    }
}
