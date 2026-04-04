import SwiftUI
import RayaChatCore

/// Intro screen — matches Android SDK IntroScreen.kt exactly.
/// No close button. Online badge top-right. Card overlaps gradient by 36pt.
struct IntroScreen: View {
    let botConfig: BotConfigProps
    let sessionCloseInfo: SessionCloseInfo?
    var onStartChat: () -> Void

    @Environment(\.rayaTheme) private var theme

    var body: some View {
        let locale = theme.locale
        let heading = botConfig.chatboxSystemHeading ?? "Hi there Raya is ready to help ✨"
        let paragraph = botConfig.chatboxSystemParagraph ?? "Ask any question — Raya is fast and friendly."
        let avatarUrl = botConfig.chatboxChatIcon.flatMap { $0.isEmpty ? nil : $0 }

        VStack(spacing: 0) {
            // Scrollable content
            ScrollView {
                VStack(spacing: 0) {
                    // ── Blue gradient header area ──
                    VStack(alignment: .leading, spacing: 0) {
                        // Top row: avatar left, online badge right
                        HStack {
                            // Avatar — only shown if configured
                            if let url = avatarUrl, let imageUrl = URL(string: url) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 56, height: 56)
                                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)

                                    AsyncImage(url: imageUrl) { image in
                                        image.resizable().scaledToFit()
                                    } placeholder: {
                                        Circle().fill(Color.white.opacity(0.3))
                                    }
                                    .frame(width: 36, height: 36)
                                    .clipShape(Circle())
                                }
                            }

                            Spacer()

                            // Online badge — white bg with border (matches Android)
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(theme.onlineDot)
                                    .frame(width: 6, height: 6)
                                Text(RayaStrings.get("online_now", locale: locale))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(theme.onlineText)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(theme.onlineBadgeBg)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(theme.onlineBadgeBorder, lineWidth: 1)
                            )
                        }

                        Spacer().frame(height: 20)

                        // Heading
                        Text(heading)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(theme.gradientForeground)
                            .lineSpacing(4)

                        Spacer().frame(height: 8)

                        // Paragraph
                        Text(paragraph)
                            .font(.system(size: 14))
                            .foregroundColor(theme.gradientForeground.opacity(0.7))
                            .lineSpacing(3)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 60) // Space for card overlap
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(theme.gradientColor.ignoresSafeArea(edges: .top))

                    // ── White card — overlaps gradient by 36pt ──
                    VStack(alignment: .leading, spacing: 0) {
                        // Session close warning
                        if let closeInfo = sessionCloseInfo {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 14))
                                    .foregroundColor(theme.isDark ? Color(hex: 0xFBBF24) : Color(hex: 0xD97706))
                                Text(closeInfo.message)
                                    .font(.system(size: 12))
                                    .foregroundColor(theme.isDark ? Color(hex: 0xFBBF24) : Color(hex: 0x92400E))
                                    .lineSpacing(2)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                (theme.isDark ? Color(hex: 0xF59E0B).opacity(0.1) : Color(hex: 0xFFFBEB))
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(theme.isDark ? Color(hex: 0xF59E0B).opacity(0.3) : Color(hex: 0xFDE68A), lineWidth: 1)
                            )
                            .padding(.bottom, 12)
                        }

                        // Description
                        Text("Start a new conversation and ask me anything")
                            .font(.system(size: 14))
                            .foregroundColor(theme.mutedForeground)

                        Spacer().frame(height: 16)

                        // Start a chat button — pill shape (28pt corners), matches Android
                        Button(action: onStartChat) {
                            HStack(spacing: 8) {
                                Text(RayaStrings.get("start_chat", locale: locale))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(theme.gradientForeground)
                                RayaIcons.send
                                    .font(.system(size: 14))
                                    .foregroundColor(theme.gradientForeground)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(theme.gradientColor)
                            .clipShape(RoundedRectangle(cornerRadius: 28))
                        }

                        Spacer().frame(height: 16)

                        // Privacy note with shield
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.shield")
                                .font(.system(size: 14))
                                .foregroundColor(theme.mutedForeground)
                                .padding(.top, 1)
                            Text("We respect your privacy. Your conversations are encrypted and never shared.")
                                .font(.system(size: 11))
                                .foregroundColor(theme.mutedForeground)
                                .lineSpacing(2)
                        }
                    }
                    .padding(20)
                    .background(theme.introCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.introCardBorder, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 5, y: 2)
                    .padding(.horizontal, 16)
                    .offset(y: -36) // Overlap into gradient — matches Android
                }
            }

            // ── Footer — full-width bar with footerBg ──
            HStack(spacing: 4) {
                Text(RayaStrings.get("powered_by", locale: locale))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.footerText)
                Text(RayaStrings.get("teammates", locale: locale))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.footerText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(theme.footerBg)
        }
        .background(theme.background)
    }
}
