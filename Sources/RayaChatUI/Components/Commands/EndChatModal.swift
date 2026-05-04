import SwiftUI
import RayaChatCore

/// Full-screen "End Chat Session" confirmation — matches Android EndChatModal.kt exactly.
/// NOT a floating card — full-screen takeover with solid theme.background.
struct EndChatModal: View {
    let botIcon: String?
    let locale: String
    var onCancel: () -> Void
    var onEndSession: () -> Void

    @Environment(\.rayaTheme) private var theme

    var body: some View {
        // Full-screen solid background (NOT semi-transparent overlay)
        ZStack {
            theme.background
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            VStack(spacing: 0) {
                // Icon in muted circle — 75pt, matches Android messageSquareX
                ZStack {
                    Circle()
                        .fill(theme.muted)
                        .frame(width: 75, height: 75)
                    let iconColor = theme.isDark ? Color(hex: 0xA1A1AA) : Color(hex: 0x71717A)
                    Image("MessageSquareXIcon", bundle: .rayaChatUI)
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(iconColor)
                        .frame(width: 32, height: 32)
                }

                Spacer().frame(height: 24)

                // Title — "End Chat Session"
                Text(RayaStrings.get("end_chat_title", locale: locale))
                    .font(RayaTypography.subheading)
                    .foregroundColor(theme.foreground)

                Spacer().frame(height: 8)

                // Subtitle — "Do you want to end this chat session?"
                Text(RayaStrings.get("end_chat_subtitle", locale: locale))
                    .font(RayaTypography.body)
                    .foregroundColor(theme.mutedForeground)

                Spacer().frame(height: 32)

                // Buttons — stacked vertically, full width, 16pt horizontal padding
                VStack(spacing: 12) {
                    // Cancel — outlined pill, 52pt height
                    Button(action: onCancel) {
                        Text(RayaStrings.get("cancel", locale: locale))
                            .font(RayaTypography.bodyBold)
                            .foregroundColor(theme.foreground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .overlay(Capsule().stroke(theme.border, lineWidth: 1.5))
                            .clipShape(Capsule())
                    }

                    // End Session — gradient filled pill, 52pt height
                    Button(action: onEndSession) {
                        Text(RayaStrings.get("end_session", locale: locale))
                            .font(RayaTypography.bodyBold)
                            .foregroundColor(theme.gradientForeground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(theme.gradientColor)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(32)
        }
    }
}
