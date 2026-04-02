import SwiftUI
import RayaChatCore

/// Pill buttons in a bot bubble for end_session command.
struct EndSessionUI: View {
    let message: String
    let options: [AnyCodable]
    let botIcon: String?
    var onSelect: (String) -> Void

    @Environment(\.rayaTheme) private var theme

    var body: some View {
        BotBubbleWrapper(botIcon: botIcon) {
            if !message.isEmpty {
                Text(message)
                    .font(RayaTypography.body)
                    .foregroundColor(theme.botBubbleForeground)
                    .padding(.bottom, 10)
            }

            HStack(spacing: 10) {
                ForEach(0..<options.count, id: \.self) { index in
                    let option = options[index].description
                    Button(action: { onSelect(option) }) {
                        Text(option)
                            .font(RayaTypography.buttonSmall)
                            .foregroundColor(theme.botBubbleForeground)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .overlay(Capsule().stroke(theme.border, lineWidth: 1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }
}

/// Shared wrapper for command UIs rendered as bot bubbles.
struct BotBubbleWrapper<Content: View>: View {
    let botIcon: String?
    @ViewBuilder let content: Content

    @Environment(\.rayaTheme) private var theme

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Bot avatar
            if let url = botIcon.flatMap({ $0.isEmpty ? nil : $0 }), let imageUrl = URL(string: url) {
                AsyncImage(url: imageUrl) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Circle().fill(theme.botBubble)
                }
                .frame(width: 28, height: 28)
                .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .padding(14)
            .frame(maxWidth: 320, alignment: .leading)
            .background(theme.botBubble)
            .clipShape(RoundedCorner(tl: 18, tr: 18, bl: 4, br: 18))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 20)
    }
}
