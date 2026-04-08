import SwiftUI

/// Scroll-to-bottom FAB — matches Android AnimatedVisibility(fadeIn+scaleIn).
/// 32pt circle, subtle shadow, thin border, chevron-down icon.
struct ScrollToBottomButton: View {
    let visible: Bool
    let action: () -> Void

    @Environment(\.rayaTheme) private var theme

    var body: some View {
        let bgColor = theme.isDark ? Color(hex: 0x27272A) : Color.white
        let borderColor = theme.isDark ? Color(hex: 0x3F3F46) : Color(hex: 0xD4D4D8)
        let iconColor = theme.isDark ? Color(hex: 0xA1A1AA) : Color(hex: 0x71717A)

        if visible {
            Button(action: action) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 32, height: 32)
                    .background(bgColor)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(borderColor, lineWidth: 0.5))
                    .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
            }
            .transition(.opacity.combined(with: .scale))
        }
    }
}
