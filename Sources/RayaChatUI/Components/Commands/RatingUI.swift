import SwiftUI
import RayaChatCore

/// 5 rating options in a bot bubble — face icons with color gradient.
struct RatingUI: View {
    let message: String
    let options: [AnyCodable]
    let botIcon: String?
    let locale: String
    var onRate: (Int) -> Void

    @State private var selected: Int = 0
    @Environment(\.rayaTheme) private var theme

    private let ratingColors: [Color] = [
        Color(hex: 0xEF4444), Color(hex: 0xF97316), Color(hex: 0xEAB308),
        Color(hex: 0x84CC16), Color(hex: 0x22C55E),
    ]
    private let ratingEmojis = ["😡", "😞", "😐", "😊", "😍"]

    var body: some View {
        BotBubbleWrapper(botIcon: botIcon) {
            if !message.isEmpty {
                Text(message)
                    .font(RayaTypography.body)
                    .foregroundColor(theme.botBubbleForeground)
                    .padding(.bottom, 12)
            }

            HStack(spacing: 0) {
                ForEach(0..<options.count, id: \.self) { index in
                    let value = (options[index].value as? Int) ?? (index + 1)
                    let isSelected = selected == value
                    let color = ratingColors[safe: index] ?? .yellow

                    Button {
                        selected = value
                        onRate(value)
                    } label: {
                        Text(ratingEmojis[safe: index] ?? "⭐")
                            .font(.system(size: 24))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(isSelected ? color.opacity(0.15) : Color.clear)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(isSelected ? color : theme.border, lineWidth: isSelected ? 2 : 0.5)
                            )
                    }
                }
            }
        }
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
