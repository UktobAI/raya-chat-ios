import SwiftUI
import RayaChatCore

/// Chat message bubble — user (gradient, right) + bot (gray, left + avatar) + system (centered).
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

        // System messages (type 4)
        if message.type == 4 {
            systemBubble
        } else if !hasContent && !hasImages {
            EmptyView()
        } else {
        HStack(alignment: .bottom, spacing: 8) {
            // Bot avatar
            if !isUser {
                botAvatar
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                // User images — above the text bubble
                if hasImages && isUser {
                    imageGrid(attachments)
                }

                // Text bubble (or bot images inside bubble)
                if hasContent || (hasImages && !isUser) {
                    let bubbleShape = isUser
                        ? RoundedCorner(tl: 18, tr: 18, bl: 18, br: 4)
                        : RoundedCorner(tl: 18, tr: 18, bl: 4, br: 18)

                    VStack(alignment: .leading, spacing: 8) {
                        // Bot images inside bubble
                        if hasImages && !isUser {
                            imageGrid(attachments)
                        }

                        if hasContent {
                            MarkdownText(
                                content: content!,
                                color: isUser ? theme.gradientForeground : theme.botBubbleForeground
                            )
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isUser ? theme.gradientColor : theme.botBubble)
                    .clipShape(bubbleShape)
                }

                // Timestamp
                if let ts = message.createdAt?.asInt64, ts > 0 {
                    Text(formatLocalTimeOrEmpty(epochSeconds: ts))
                        .font(RayaTypography.tiny)
                        .foregroundColor(theme.mutedForeground)
                        .padding(.horizontal, 4)
                }
            }
            .frame(maxWidth: 300, alignment: isUser ? .trailing : .leading)

            if isUser { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        } // else
    }

    // MARK: - Subviews

    @ViewBuilder
    private var botAvatar: some View {
        if let url = botIcon.flatMap({ $0.isEmpty ? nil : $0 }), let imageUrl = URL(string: url) {
            AsyncImage(url: imageUrl) { image in
                image.resizable().scaledToFit()
            } placeholder: {
                Circle().fill(theme.botBubble)
            }
            .frame(width: 28, height: 28)
            .clipShape(Circle())
        }
    }

    @ViewBuilder
    private var systemBubble: some View {
        HStack {
            Spacer()
            Text(message.content ?? "")
                .font(RayaTypography.caption)
                .foregroundColor(theme.systemMessageForeground)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(theme.systemMessage)
                .clipShape(Capsule())
            Spacer()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func imageGrid(_ attachments: [Attachment]) -> some View {
        HStack(spacing: 4) {
            ForEach(attachments.prefix(Constants.maxImagesPerMessage), id: \.url) { att in
                if let url = URL(string: att.url) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(theme.surfaceVariant)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .onTapGesture { onImagePress?(att.url) }
                }
            }
        }
    }
}

// MARK: - String Extension

extension String {
    var asInt64: Int64? { Int64(self) }
}
