import SwiftUI
import RayaChatCore

/// Full-screen confirmation overlay for ending the chat session.
struct EndChatModal: View {
    let botIcon: String?
    let locale: String
    var onCancel: () -> Void
    var onEndSession: () -> Void

    @Environment(\.rayaTheme) private var theme

    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onCancel() }

            // Modal card
            VStack(spacing: 20) {
                // Bot icon
                if let url = botIcon.flatMap({ $0.isEmpty ? nil : $0 }), let imageUrl = URL(string: url) {
                    AsyncImage(url: imageUrl) { image in
                        image.resizable().scaledToFit()
                    } placeholder: {
                        Circle().fill(theme.surfaceVariant)
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
                }

                Text(RayaStrings.get("end_chat_title", locale: locale))
                    .font(RayaTypography.subheading)
                    .foregroundColor(theme.foreground)

                Text(RayaStrings.get("end_chat_message", locale: locale))
                    .font(RayaTypography.body)
                    .foregroundColor(theme.mutedForeground)
                    .multilineTextAlignment(.center)

                // Buttons — stacked vertically
                VStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text(RayaStrings.get("cancel", locale: locale))
                            .font(RayaTypography.bodyBold)
                            .foregroundColor(theme.foreground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .overlay(Capsule().stroke(theme.border, lineWidth: 1.5))
                            .clipShape(Capsule())
                    }

                    Button(action: onEndSession) {
                        Text(RayaStrings.get("end_session", locale: locale))
                            .font(RayaTypography.bodyBold)
                            .foregroundColor(theme.gradientForeground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(theme.gradientColor)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(32)
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
            .padding(.horizontal, 32)
        }
    }
}
