import SwiftUI
import RayaChatCore

/// Circular countdown timer in a bot bubble — matches Android CountdownClose.kt.
/// 3 seconds, 32pt circle, 3pt stroke, starts at top center.
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
                // Circular countdown — 32pt, 3pt stroke (matches Android)
                ZStack {
                    Circle()
                        .stroke(theme.border, lineWidth: 3)
                        .frame(width: 32, height: 32)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(theme.gradientColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90)) // start at top center
                    Text("\(count)")
                        .font(.system(size: 12, weight: .semibold)) // matches Android 12.sp
                        .foregroundColor(theme.botBubbleForeground)
                }

                Text("Ending session...")
                    .font(RayaTypography.caption)
                    .foregroundColor(theme.mutedForeground)
            }
        }
        .task(id: message) {
            for _ in 0..<Constants.feedbackCountdownSeconds {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if count > 0 { count -= 1 }
            }
            onComplete()
        }
    }
}
