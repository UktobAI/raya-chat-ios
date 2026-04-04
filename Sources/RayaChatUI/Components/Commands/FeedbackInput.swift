import SwiftUI
import RayaChatCore

/// Textarea + Skip/Submit in a bot bubble — matches Android FeedbackInput.kt.
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

            // Text input — min 100pt height (matches Android heightIn(min = 100.dp))
            TextEditor(text: $feedback)
                .font(RayaTypography.body)
                .foregroundColor(theme.foreground)
                .frame(minHeight: 100)
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
                .onChange(of: feedback) { newValue in
                    // Enforce max length (matches Android MAX_FEEDBACK_LENGTH = 200)
                    if newValue.count > Constants.maxFeedbackLength {
                        feedback = String(newValue.prefix(Constants.maxFeedbackLength))
                    }
                }

            // Counter + buttons row (matches Android Row with SpaceBetween)
            HStack {
                // Counter — "X/200 characters" (matches Android format)
                Text("\(feedback.count)/\(Constants.maxFeedbackLength) characters")
                    .font(RayaTypography.caption)
                    .foregroundColor(theme.mutedForeground)

                Spacer()

                HStack(spacing: 8) {
                    if optional {
                        Button(action: { onSubmit("") }) {
                            Text(RayaStrings.get("skip", locale: locale))
                                .font(RayaTypography.buttonSmall)
                                .foregroundColor(theme.foreground)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .overlay(Capsule().stroke(theme.border, lineWidth: 1))
                        }
                    }

                    Button(action: { onSubmit(feedback.trimmingCharacters(in: .whitespacesAndNewlines)) }) {
                        Text(RayaStrings.get("submit", locale: locale))
                            .font(RayaTypography.buttonSmall)
                            .foregroundColor(theme.gradientForeground)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(theme.gradientColor)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.top, 8)
        }
    }
}
