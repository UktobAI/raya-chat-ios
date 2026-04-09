import SwiftUI
import RayaChatCore

/// Message composer with image preview, text input, and action buttons.
/// Images are staged in preview — sent only when user taps send.
struct MessageComposer: View {
    var placeholder: String?
    var enableImageUpload: Bool = true
    var enableVoiceNote: Bool = true
    var imagePickerAdapter: (any ImagePickerAdapter)?
    var hasAudioAdapter: Bool = false
    var disabled: Bool = false
    var locale: String = "en"
    var onSendMessage: (String) -> Void
    var onSendImages: (([ImagePayload], String) -> Void)?
    var onMicPress: (() -> Void)?

    @State private var text = ""
    @State private var selectedImages: [ImageAsset] = []
    @FocusState private var isFocused: Bool
    @Environment(\.rayaTheme) private var theme

    private var hasText: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var hasImages: Bool { !selectedImages.isEmpty }
    private var canSend: Bool { (hasText || hasImages) && !disabled }
    private var actualPlaceholder: String { placeholder ?? RayaStrings.get("type_message", locale: locale) }
    private var iconColor: Color { Color(hex: 0xA1A1AA) }

    var body: some View {
        VStack(spacing: 0) {
            // Image preview above the card
            if hasImages {
                ImagePickerPreview(images: selectedImages) { index in
                    selectedImages.remove(at: index)
                }
                .padding(.bottom, 2)
            }

            // Card
            VStack(spacing: 8) {
                // Text field
                TextField(actualPlaceholder, text: $text)
                    .font(RayaTypography.input)
                    .foregroundColor(theme.foreground)
                    .focused($isFocused)
                    .lineLimit(6)
                    .padding(.vertical, 2)

                // Button row
                HStack {
                    // Left: action icons
                    HStack(spacing: 6) {
                        composerButton(icon: RayaIcons.smile, label: "Emoji") { }

                        if enableImageUpload && imagePickerAdapter != nil {
                            composerButton(icon: RayaIcons.paperclip, label: "Attach") {
                                handlePickImages()
                            }
                        }

                        if enableVoiceNote && hasAudioAdapter {
                            composerButton(icon: RayaIcons.mic, label: "Record") {
                                onMicPress?()
                            }
                        }
                    }

                    Spacer()

                    // Right: Send button — Lucide send icon in circle
                    Button(action: handleSend) {
                        let sendColor = theme.isDark ? Color.white : Color(hex: 0x3F3F46)
                        LucideSendIcon()
                            .fill(sendColor, style: FillStyle(eoFill: true))
                            .frame(width: 18, height: 18)
                            .frame(width: 38, height: 38)
                            .background(theme.sendBtnBg)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, hasImages ? 2 : 8)
            .padding(.bottom, 10)
            .background(theme.composerBg)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isFocused ? theme.composerBorderFocused : theme.composerBorder, lineWidth: 1)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(theme.background)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func composerButton(icon: Image, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            icon
                .font(.system(size: 22))
                .foregroundColor(iconColor)
                .frame(width: 36, height: 36)
        }
    }

    private func handleSend() {
        guard canSend else { return }

        if hasImages {
            let payloads = selectedImages.map {
                ImagePayload(name: $0.name, type: $0.type, base64: $0.base64, uri: $0.uri)
            }
            onSendImages?(payloads, text.trimmingCharacters(in: .whitespacesAndNewlines))
            selectedImages = []
            text = ""
        } else if hasText {
            onSendMessage(text.trimmingCharacters(in: .whitespacesAndNewlines))
            text = ""
        }
        isFocused = false // Dismiss keyboard after send
    }

    private func handlePickImages() {
        guard !disabled, let adapter = imagePickerAdapter else { return }
        Task {
            do {
                let remaining = Constants.maxImagesPerMessage - selectedImages.count
                guard remaining > 0 else { return }
                let picked = try await adapter.pickImages(maxCount: remaining)
                if !picked.isEmpty {
                    await MainActor.run {
                        selectedImages = (selectedImages + picked).prefix(Constants.maxImagesPerMessage).map { $0 }
                    }
                }
            } catch {
                // Picker cancelled or failed
            }
        }
    }
}
