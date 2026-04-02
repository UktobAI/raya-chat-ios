import SwiftUI
import RayaChatCore

/// Textarea + Skip/Submit in a bot bubble for feedback collection.
struct FeedbackInput: View {
    let message: String
    let optional: Bool
    let botIcon: String?
    let locale: String
    var onSubmit: (String) -> Void

    @State private var feedback = ""
    @Environment(\.rayaTheme) private var theme

    var body: some View {
        BotBubbleWrapper(botIcon: botIcon) {
            if !message.isEmpty {
                Text(message)
                    .font(RayaTypography.body)
                    .foregroundColor(theme.botBubbleForeground)
                    .padding(.bottom, 8)
            }

            // Text input
            TextEditor(text: $feedback)
                .font(RayaTypography.body)
                .foregroundColor(theme.foreground)
                .frame(minHeight: 80, maxHeight: 120)
                .padding(8)
                .background(theme.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.inputBorder, lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if feedback.isEmpty {
                        Text(RayaStrings.get("feedback_placeholder", locale: locale))
                            .font(RayaTypography.body)
                            .foregroundColor(theme.mutedForeground)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .allowsHitTesting(false)
                    }
                }

            // Counter + buttons
            HStack {
                Text("\(feedback.count)/\(Constants.maxFeedbackLength)")
                    .font(RayaTypography.tiny)
                    .foregroundColor(theme.mutedForeground)

                Spacer()

                if optional {
                    Button(action: { onSubmit("") }) {
                        Text(RayaStrings.get("skip", locale: locale))
                            .font(RayaTypography.buttonSmall)
                            .foregroundColor(theme.foreground)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .overlay(Capsule().stroke(theme.border, lineWidth: 1))
                    }
                }

                Button(action: { onSubmit(feedback.trimmingCharacters(in: .whitespacesAndNewlines)) }) {
                    Text(RayaStrings.get("submit", locale: locale))
                        .font(RayaTypography.buttonSmall)
                        .foregroundColor(theme.gradientForeground)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(theme.gradientColor)
                        .clipShape(Capsule())
                }
            }
            .padding(.top, 8)
        }
    }
}
