import SwiftUI
import RayaChatCore

/// Gradient header bar with bot icon, back button, and close button.
struct Header: View {
    let botIcon: String?
    var showBackButton = false
    var showCloseButton = true
    var showBotIcon = true
    var onBack: (() -> Void)?
    var onClose: (() -> Void)?

    @Environment(\.rayaTheme) private var theme

    var body: some View {
        let avatarUrl = botIcon.flatMap { $0.isEmpty ? nil : $0 }

        ZStack {
            // Gradient background
            LinearGradient(
                colors: [theme.gradientColor, theme.gradientColor.opacity(0.85)],
                startPoint: .leading, endPoint: .trailing
            )

            HStack(spacing: 8) {
                // Back button
                if showBackButton, let onBack {
                    Button(action: onBack) {
                        RayaIcons.chevronLeft
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(theme.gradientForeground)
                    }
                    .frame(width: 32, height: 32)
                }

                // Bot icon
                if showBotIcon, let url = avatarUrl, let imageUrl = URL(string: url) {
                    AsyncImage(url: imageUrl) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Circle().fill(Color.white.opacity(0.3))
                    }
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                    .background(Circle().fill(Color.white.opacity(0.9)).frame(width: 40, height: 40))
                }

                Spacer()

                // Close button
                if showCloseButton, let onClose {
                    Button(action: onClose) {
                        RayaIcons.close
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.gradientForeground)
                    }
                    .frame(width: 32, height: 32)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: 56)
    }
}
