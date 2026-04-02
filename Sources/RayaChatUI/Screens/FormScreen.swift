import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
import RayaChatCore

/// Field identifiers for focus management.
enum FormField: Hashable { case name, email, phone }

/// Form screen — user info collection with validation.
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
    @FocusState private var focusedField: FormField?

    var body: some View {
        let locale = theme.locale

        VStack(spacing: 0) {
            // Header with back button
            Header(
                botIcon: botConfig.chatboxChatIcon,
                showBackButton: true,
                showCloseButton: false,
                showBotIcon: false,
                onBack: onBack
            )

            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 32)

                    // Avatar circle
                    ZStack {
                        Circle()
                            .fill(theme.gradientColor)
                            .frame(width: 44, height: 44)
                        RayaIcons.user
                            .font(.system(size: 22))
                            .foregroundColor(theme.gradientForeground)
                    }
                    .zIndex(1)

                    // Card — overlaps avatar by 22pt
                    VStack(spacing: 14) {
                        // Welcome text
                        Text(RayaStrings.get("welcome_form", locale: locale))
                            .font(RayaTypography.body)
                            .foregroundColor(theme.mutedForeground)
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 6)

                        // Full Name
                        FormInput(
                            text: $fullName,
                            placeholder: RayaStrings.get("full_name", locale: locale),
                            hasError: errors.contains("fullName"),
                            errorText: RayaStrings.get("error_name", locale: locale),
                            focused: $focusedField,
                            field: .name,
                            nextField: botConfig.enableUserEmail ? .email : (botConfig.enableUserPhone ? .phone : nil)
                        )

                        // Email
                        if botConfig.enableUserEmail {
                            FormInput(
                                text: $email,
                                placeholder: RayaStrings.get("email", locale: locale),
                                hasError: errors.contains("email"),
                                errorText: RayaStrings.get("error_email", locale: locale),
                                isEmail: true,
                                focused: $focusedField,
                                field: .email,
                                nextField: botConfig.enableUserPhone ? .phone : nil,
                                onBlurValidate: {
                                    if !email.isEmpty && !validateEmail(email.trimmingCharacters(in: .whitespaces)) {
                                        errors.insert("email")
                                    } else {
                                        errors.remove("email")
                                    }
                                }
                            )
                        }

                        // Phone
                        if botConfig.enableUserPhone {
                            FormInput(
                                text: $phone,
                                placeholder: RayaStrings.get("phone_number", locale: locale),
                                hasError: errors.contains("phone"),
                                errorText: RayaStrings.get("error_phone", locale: locale),
                                isPhone: true,
                                focused: $focusedField,
                                field: .phone,
                                nextField: nil
                            )
                        }

                        // Submit button
                        Button(action: handleSubmit) {
                            HStack(spacing: 8) {
                                Text(isLoading ? RayaStrings.get("starting_chat", locale: locale) : RayaStrings.get("start_the_chat", locale: locale))
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
                    .padding(.top, 36)
                    .padding(.bottom, 24)
                    .padding(.horizontal, 24)
                    .background(theme.formCardBg)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(theme.border, lineWidth: 1))
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                    .offset(y: -22)
                    .padding(.horizontal, 20)
                }
            }
        }
        .background(theme.background)
    }

    private func handleSubmit() {
        errors.removeAll()

        let trimmedName = fullName.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)

        if trimmedName.isEmpty { errors.insert("fullName") }
        if botConfig.enableUserEmail && trimmedEmail.isEmpty { errors.insert("email") }
        if botConfig.enableUserEmail && !trimmedEmail.isEmpty && !validateEmail(trimmedEmail) { errors.insert("email") }
        if botConfig.enableUserPhone && !trimmedPhone.isEmpty && !validatePhone(trimmedPhone) { errors.insert("phone") }

        guard errors.isEmpty else { return }

        isLoading = true
        let userInfo = UserInfo(fullName: trimmedName, email: trimmedEmail, phone: trimmedPhone)
        onSubmit(userInfo)
    }
}

// MARK: - Form Input

private struct FormInput: View {
    @Binding var text: String
    let placeholder: String
    let hasError: Bool
    let errorText: String
    var isEmail: Bool = false
    var isPhone: Bool = false
    var focused: FocusState<FormField?>.Binding
    var field: FormField
    var nextField: FormField?
    var onBlurValidate: (() -> Void)?

    @Environment(\.rayaTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            let textField = TextField(placeholder, text: $text)
                .font(RayaTypography.input)
                .foregroundColor(theme.foreground)
                .autocorrectionDisabled()
                .submitLabel(nextField != nil ? .next : .done)
                .focused(focused, equals: field)
                .onSubmit {
                    onBlurValidate?()
                    if let next = nextField {
                        focused.wrappedValue = next
                    }
                }
                .frame(height: 48)
                .padding(.horizontal, 14)
                .background(theme.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(hasError ? theme.errorRed : theme.inputBorder, lineWidth: 1)
                )

            #if canImport(UIKit)
            textField.keyboardType(isEmail ? .emailAddress : isPhone ? .phonePad : .default)
            #else
            textField
            #endif

            if hasError {
                HStack(spacing: 4) {
                    RayaIcons.exclamation
                        .font(.system(size: 10))
                        .foregroundColor(theme.errorRed)
                    Text(errorText)
                        .font(RayaTypography.tiny)
                        .foregroundColor(theme.errorRed)
                }
            }
        }
    }
}
