import SwiftUI
import RayaChatCore

/// Circular countdown timer in a bot bubble — shown after feedback_received.
struct CountdownClose: View {
    let message: String
    let botIcon: String?
    let locale: String
    var onComplete: () -> Void

    @State private var count = Constants.feedbackCountdownSeconds
    @Environment(\.rayaTheme) private var theme

    private var progress: CGFloat {
        CGFloat(count) / CGFloat(Constants.feedbackCountdownSeconds)
    }

    var body: some View {
        BotBubbleWrapper(botIcon: botIcon) {
            if !message.isEmpty {
                Text(message)
                    .font(RayaTypography.body)
                    .foregroundColor(theme.botBubbleForeground)
                    .padding(.bottom, 10)
            }

            HStack(spacing: 10) {
                // Circular countdown
                ZStack {
                    Circle()
                        .stroke(theme.border, lineWidth: 2)
                        .frame(width: 28, height: 28)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(theme.gradientColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 28, height: 28)
                        .rotationEffect(.degrees(-90))
                    Text("\(count)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(theme.botBubbleForeground)
                }

                Text(RayaStrings.get("session_closed", locale: locale))
                    .font(RayaTypography.caption)
                    .foregroundColor(theme.mutedForeground)
            }
        }
        .task(id: message) {
            for _ in 0..<Constants.feedbackCountdownSeconds {
                try? await Task.sleep(for: .seconds(1))
                if count > 0 { count -= 1 }
            }
            onComplete()
        }
    }
}
