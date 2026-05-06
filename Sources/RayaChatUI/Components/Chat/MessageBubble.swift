import SwiftUI
import RayaChatCore

/// Chat message bubble — matches Android SDK MessageBubble.kt.
struct MessageBubble: View {
    let message: TypeMessage
    let botIcon: String?
    var onImagePress: ((String) -> Void)?

    @Environment(\.rayaTheme) private var theme

    var body: some View {
        let isUser = message.sender == 1
        let content = message.content
        let hasContent = !(content ?? "").isEmpty
        let attachments = message.attachments
        let hasImages = !attachments.isEmpty
        let avatarUrl = botIcon.flatMap { $0.isEmpty ? nil : $0 }
        let timestamp = formatLocalTimeOrEmpty(epochSeconds: message.createdAt.flatMap { Int64($0) })

        if message.type == 4 {
            // System message
            HStack {
                Spacer()
                Text(message.content ?? "")
                    .font(RayaTypography.caption)
                    .foregroundColor(theme.systemMessageForeground)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(theme.systemMessage)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        } else if message.type == 2, let audio = message.audio, !audio.audioUrls.isEmpty {
            // Audio message
            audioMessageRow(uri: audio.audioUrls, isUser: isUser, timestamp: timestamp, avatarUrl: avatarUrl)
        } else if hasContent || hasImages {
            // ── Normal message ──
            // Outer Column: full width, aligned to trailing (user) or leading (bot)
            VStack(alignment: isUser ? .trailing : .leading, spacing: 0) {

                if isUser && hasImages {
                    // User image message
                    userImageSection(attachments, content, timestamp)
                } else {
                    // ── Row: [avatar] [bubble] ──
                    HStack(alignment: .bottom, spacing: 8) {
                        if !isUser, let url = avatarUrl, let imageUrl = URL(string: url) {
                            AsyncImage(url: imageUrl) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                Circle().fill(theme.botBubble)
                            }
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                        }

                        // ── Bubble ──
                        let bubbleShape = isUser
                            ? RoundedCorner(tl: 16, tr: 16, bl: 16, br: 4)
                            : RoundedCorner(tl: 16, tr: 16, bl: 4, br: 16)
                        let bubbleBg = isUser ? theme.gradientColor : theme.botBubble
                        let textColor = isUser ? theme.gradientForeground : theme.botBubbleForeground

                        VStack(alignment: .leading, spacing: 8) {
                            if !isUser && hasImages {
                                botImageGrid(attachments)
                            }
                            if hasContent {
                                if !isUser {
                                    MarkdownText(content: content!, color: textColor)
                                } else {
                                    Text(content!)
                                        .font(RayaTypography.body)
                                        .foregroundColor(textColor)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, isUser ? 8 : 16)
                        .background(bubbleBg)
                        .clipShape(bubbleShape)
                    }

                    // ── Timestamp — ALWAYS shown if available (both user and bot) ──
                    if !timestamp.isEmpty {
                        Text(timestamp)
                            .font(.system(size: 10))
                            .foregroundColor(theme.mutedForeground)
                            .padding(.top, 8)
                            .padding(.leading, (!isUser && avatarUrl != nil) ? 36 : 0)
                    }
                }

                // 20pt spacer (matches Android Spacer(Modifier.height(20.dp)))
                Color.clear.frame(height: 20)
            }
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
            .padding(.horizontal, 12)
        }
    }

    // MARK: - User Image Section

    @ViewBuilder
    private func userImageSection(_ attachments: [Attachment], _ content: String?, _ timestamp: String) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            HStack(spacing: 6) {
                ForEach(attachments.prefix(Constants.maxImagesPerMessage), id: \.url) { att in
                    if let url = URL(string: att.url) {
                        AsyncImage(url: url) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 6).fill(theme.surfaceVariant)
                        }
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .onTapGesture { onImagePress?(att.url) }
                    }
                }
            }

            if let content, !content.isEmpty {
                Text(content)
                    .font(RayaTypography.body)
                    .foregroundColor(theme.gradientForeground)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(theme.gradientColor)
                    .clipShape(RoundedCorner(tl: 16, tr: 16, bl: 16, br: 4))
                    .padding(.top, 8)
            }

            if !timestamp.isEmpty {
                Text(timestamp)
                    .font(.system(size: 10))
                    .foregroundColor(theme.mutedForeground)
                    .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Audio Message

    @ViewBuilder
    private func audioMessageRow(uri: String, isUser: Bool, timestamp: String, avatarUrl: String?) -> some View {
        VStack(alignment: isUser ? .trailing : .leading, spacing: 0) {
            HStack(alignment: .bottom, spacing: 8) {
                if !isUser, let url = avatarUrl, let imageUrl = URL(string: url) {
                    AsyncImage(url: imageUrl) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Circle().fill(theme.botBubble)
                    }
                    .frame(width: 28, height: 28)
                    .clipShape(Circle())
                }
                AudioMessageBubble(uri: uri, isUser: isUser)
                    .frame(maxWidth: 260)
                if isUser { Spacer(minLength: 0) }
            }
            .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)

            if !timestamp.isEmpty {
                Text(timestamp)
                    .font(.system(size: 10))
                    .foregroundColor(theme.mutedForeground)
                    .padding(.top, 8)
                    .padding(.leading, (!isUser && avatarUrl != nil) ? 36 : 0)
            }

            Color.clear.frame(height: 20)
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
        .padding(.horizontal, 12)
    }

    // MARK: - Bot Image Grid

    @ViewBuilder
    private func botImageGrid(_ attachments: [Attachment]) -> some View {
        HStack(spacing: 4) {
            ForEach(attachments.prefix(Constants.maxImagesPerMessage), id: \.url) { att in
                if let url = URL(string: att.url) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8).fill(theme.surfaceVariant)
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture { onImagePress?(att.url) }
                }
            }
        }
    }
}

extension String {
    var asInt64: Int64? { Int64(self) }
}

/// Wrapper that owns one audio player adapter per audio message bubble, so
/// scrolling between audio messages doesn't share a single player's state.
private struct AudioMessageBubble: View {
    let uri: String
    let isUser: Bool

    #if canImport(AVFAudio) && os(iOS)
    @State private var adapter: DefaultAudioPlayerAdapter = .init()
    #endif

    var body: some View {
        #if canImport(AVFAudio) && os(iOS)
        AudioPlayerUI(uri: uri, adapter: adapter)
        #else
        EmptyView()
        #endif
    }
}
