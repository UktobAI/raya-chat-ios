import SwiftUI
import RayaChatCore

/// Intro screen — gradient header, avatar, "Online now" badge, heading, card with button, footer.
struct IntroScreen: View {
    let botConfig: BotConfigProps
    let sessionCloseInfo: SessionCloseInfo?
    var onStartChat: () -> Void
    var onClose: () -> Void

    @Environment(\.rayaTheme) private var theme
    @Environment(\.openURL) private var openURL

    var body: some View {
        let locale = theme.locale
        let heading = botConfig.chatboxSystemHeading ?? "Hi there Raya is ready to help ✨"
        let paragraph = botConfig.chatboxSystemParagraph ?? "Ask any question — Raya is fast and friendly."
        let avatarUrl = botConfig.chatboxChatIcon.flatMap { $0.isEmpty ? nil : $0 }

        VStack(spacing: 0) {
            // Gradient header area
            ZStack(alignment: .topTrailing) {
                LinearGradient(
                    colors: [theme.gradientColor, theme.gradientColor.opacity(0.85)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )

                // Close button
                Button(action: onClose) {
                    RayaIcons.close
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.gradientForeground)
                        .frame(width: 32, height: 32)
                }
                .padding(.top, 12)
                .padding(.trailing, 16)

                VStack(spacing: 0) {
                    Spacer().frame(height: 20)

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            // Avatar + Online badge
                            HStack(spacing: 12) {
                                if let url = avatarUrl, let imageUrl = URL(string: url) {
                                    AsyncImage(url: imageUrl) { image in
                                        image.resizable().scaledToFit()
                                    } placeholder: {
                                        Circle().fill(Color.white.opacity(0.3))
                                    }
                                    .frame(width: 36, height: 36)
                                    .background(Circle().fill(Color.white).frame(width: 48, height: 48))
                                    .clipShape(Circle())
                                }

                                // Online badge
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(Color(hex: 0x22C55E))
                                        .frame(width: 6, height: 6)
                                    Text(RayaStrings.get("online_now", locale: locale))
                                        .font(RayaTypography.caption)
                                        .foregroundColor(theme.gradientForeground.opacity(0.9))
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Capsule())
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)

                    // Heading + paragraph
                    VStack(alignment: .leading, spacing: 6) {
                        Text(heading)
                            .font(RayaTypography.heading)
                            .foregroundColor(theme.gradientForeground)
                        Text(paragraph)
                            .font(RayaTypography.body)
                            .foregroundColor(theme.gradientForeground.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .frame(height: 220)

            // White card area
            VStack(spacing: 16) {
                // Session close warning
                if let closeInfo = sessionCloseInfo {
                    HStack(spacing: 8) {
                        RayaIcons.exclamation
                            .font(.system(size: 14))
                            .foregroundColor(theme.errorRed)
                        Text(closeInfo.message)
                            .font(RayaTypography.caption)
                            .foregroundColor(theme.errorRed)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.errorRed.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.errorRed.opacity(0.2), lineWidth: 0.5))
                }

                // Start chat button
                Button(action: onStartChat) {
                    Text(RayaStrings.get("start_chat", locale: locale))
                        .font(RayaTypography.bodyBold)
                        .foregroundColor(theme.gradientForeground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(theme.gradientColor)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Privacy note
                Text(RayaStrings.get("privacy_note", locale: locale))
                    .font(RayaTypography.tiny)
                    .foregroundColor(theme.mutedForeground)
                    .multilineTextAlignment(.center)
            }
            .padding(20)
            .background(theme.introCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.introCardBorder, lineWidth: 1))
            .padding(.horizontal, 16)
            .offset(y: -20)

            Spacer()

            // Footer — Powered by
            HStack(spacing: 4) {
                Text(RayaStrings.get("powered_by", locale: locale))
                    .font(RayaTypography.tiny)
                    .foregroundColor(theme.footerText)
                Text(RayaStrings.get("teammates", locale: locale))
                    .font(RayaTypography.tiny)
                    .foregroundColor(theme.footerText)
                    .fontWeight(.semibold)
            }
            .padding(.bottom, 16)
        }
        .background(theme.background)
    }
}
