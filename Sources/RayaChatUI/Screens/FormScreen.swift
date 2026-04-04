import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import RayaChatCore

/// Form screen — matches Android SDK FormScreen.kt exactly.
/// Gradient header with back button, avatar circle overlapping white card,
/// clean inputs with 1px border, gradient submit button.
struct FormScreen: View {
    let botConfig: BotConfigProps
    var onSubmit: (UserInfo) -> Void
    var onBack: () -> Void

    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var errors: Set<String> = []
    @State private var isLoading = false
    @Environment(\.rayaTheme) private var theme

    var body: some View {
        let locale = theme.locale

        VStack(spacing: 0) {
            // Header handles ignoresSafeArea internally — no duplicate needed
            Header(
                botIcon: botConfig.chatboxChatIcon,
                showBackButton: true,
                showCloseButton: false,
                showBotIcon: false,
                onBack: onBack
            )

            // ── Scrollable content ──
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 32)

                    // Avatar circle — overlaps into card below
                    ZStack {
                        Circle()
                            .fill(theme.gradientColor)
                            .frame(width: 44, height: 44)
                        Image(systemName: "person")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(theme.gradientForeground)
                    }
                    .zIndex(1)

                    // ── White card — overlaps avatar by 22pt ──
                    VStack(spacing: 0) {
                        // Welcome text — centered
                        Text("Welcome to our live chat! Please fill in the form below before starting the chat.")
                            .font(.system(size: 14))
                            .foregroundColor(theme.mutedForeground)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .padding(.bottom, 20)

                        // Full Name
                        SimpleFormInput(
                            text: $fullName,
                            placeholder: RayaStrings.get("full_name", locale: locale),
                            hasError: errors.contains("fullName"),
                            errorText: RayaStrings.get("error_name", locale: locale),
                            onClearError: { errors.remove("fullName") }
                        )

                        Spacer().frame(height: 14)

                        // Email
                        if botConfig.enableUserEmail {
                            SimpleFormInput(
                                text: $email,
                                placeholder: RayaStrings.get("email", locale: locale),
                                hasError: errors.contains("email"),
                                errorText: RayaStrings.get("error_email", locale: locale),
                                onClearError: { errors.remove("email") }
                            )
                            Spacer().frame(height: 14)
                        }

                        // Phone
                        if botConfig.enableUserPhone {
                            SimpleFormInput(
                                text: $phone,
                                placeholder: RayaStrings.get("phone_number", locale: locale),
                                hasError: errors.contains("phone"),
                                errorText: RayaStrings.get("error_phone", locale: locale),
                                onClearError: { errors.remove("phone") }
                            )
                            Spacer().frame(height: 14)
                        }

                        // Submit button — 48pt height, 8pt corners, gradient bg
                        Button(action: handleSubmit) {
                            HStack(spacing: 8) {
                                Text(isLoading
                                     ? RayaStrings.get("starting_chat", locale: locale)
                                     : RayaStrings.get("start_the_chat", locale: locale))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(theme.gradientForeground)
                                if isLoading {
                                    ProgressView()
                                        .tint(theme.gradientForeground)
                                        .scaleEffect(0.7)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(isLoading ? theme.gradientColor.opacity(0.7) : theme.gradientColor)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(isLoading)
                    }
                    .padding(.top, 36) // space for avatar overlap
                    .padding(.bottom, 24)
                    .padding(.horizontal, 24)
                    .background(theme.formCardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.border, lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                    .offset(y: -22) // overlap avatar
                    .padding(.horizontal, 20)
                }
            }
        }
        .background(theme.background)
        .background(alignment: .top) {
            theme.gradientColor.frame(height: 100).ignoresSafeArea(edges: .top)
        }
    }

    private func handleSubmit() {
        errors.removeAll()

        let trimmedName = fullName.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)

        if trimmedName.isEmpty { errors.insert("fullName") }
        if botConfig.enableUserEmail && trimmedEmail.isEmpty { errors.insert("email") }
        if botConfig.enableUserEmail && !trimmedEmail.isEmpty && !validateEmail(trimmedEmail) { errors.insert("email") }
        if botConfig.enableUserPhone && trimmedPhone.isEmpty { errors.insert("phone") }

        guard errors.isEmpty else { return }

        // Dismiss keyboard before transition — matches Android focusManager.clearFocus()
        #if canImport(UIKit)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        #endif

        isLoading = true
        onSubmit(UserInfo(fullName: trimmedName, email: trimmedEmail, phone: trimmedPhone))
    }
}

// MARK: - Simple Form Input

/// Minimal text field — uses SwiftUI's built-in prompt to avoid ZStack/FocusState overhead.
private struct SimpleFormInput: View {
    @Binding var text: String
    let placeholder: String
    let hasError: Bool
    let errorText: String
    var onClearError: () -> Void = {}

    @Environment(\.rayaTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(
                placeholder,
                text: Binding(get: { text }, set: { text = $0; onClearError() })
            )
            .font(.system(size: 14))
            .foregroundColor(theme.foreground)
            .autocorrectionDisabled()
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(theme.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(hasError ? theme.errorRed : theme.inputBorder, lineWidth: 1)
            )

            if hasError {
                HStack(spacing: 4) {
                    Text("⚠").font(.system(size: 12)).foregroundColor(theme.errorRed)
                    Text(errorText).font(.system(size: 12)).foregroundColor(theme.errorRed)
                }
            }
        }
    }
}
