import SwiftUI
import RayaChatCore

/// Chat screen — header + message list + footer + composer.
struct ChatScreen: View {
    @ObservedObject var client: RayaChatClient
    let botConfig: BotConfigProps
    var imagePickerAdapter: (any ImagePickerAdapter)?
    var audioRecorderAdapter: (any AudioRecorderAdapter)?
    var onClose: () -> Void
    var onEndSession: () -> Void

    @State private var fullScreenImage: String?
    @Environment(\.rayaTheme) private var theme

    var body: some View {
        let locale = theme.locale
        let chatIcon = botConfig.chatboxChatIcon

        ZStack {
            VStack(spacing: 0) {
                // Header
                Header(
                    botIcon: chatIcon,
                    showCloseButton: true,
                    onClose: onClose
                )

                // Message list with footer
                MessageList(
                    messages: client.messages,
                    currentMessage: client.currentMessage,
                    botIcon: chatIcon,
                    onImagePress: { uri in fullScreenImage = uri },
                    footerContent: {
                        ChatFooter(
                            loading: client.loading,
                            isStreaming: !client.currentMessage.isEmpty,
                            info: client.info,
                            showHumanAgentBtn: client.showHumanAgentBtn,
                            commandData: client.commandData,
                            presets: client.presets,
                            messagesCount: client.messages.count,
                            botConfig: botConfig,
                            chatIcon: chatIcon,
                            locale: locale,
                            onSendMessage: { client.sendMessage($0) },
                            onSendPreset: { client.sendPreset($0) },
                            onSendCommandResponse: { cmd, resp in client.sendCommandResponse(command: cmd, response: resp) },
                            onEndSession: onEndSession
                        )
                    },
                    footerChangeSignal: footerSignal
                )

                // Composer
                MessageComposer(
                    placeholder: client.commandData != nil ? RayaStrings.get("select_option", locale: locale) : botConfig.chatboxPlaceholder,
                    enableImageUpload: botConfig.enableImageUpload,
                    enableVoiceNote: botConfig.enableVoiceNote,
                    imagePickerAdapter: imagePickerAdapter,
                    hasAudioAdapter: audioRecorderAdapter != nil,
                    disabled: client.commandData != nil || (client.loading && client.currentMessage.isEmpty),
                    locale: locale,
                    onSendMessage: { client.sendMessage($0) },
                    onSendImages: { images, caption in client.sendImages(images, caption: caption) },
                    onMicPress: nil // TODO: audio recorder overlay
                )
            }
            .background(theme.background)

            // Full-screen image viewer
            if fullScreenImage != nil {
                ImageViewer(imageUri: fullScreenImage) {
                    fullScreenImage = nil
                }
            }
        }
    }

    private var footerSignal: Int {
        var hasher = Hasher()
        hasher.combine(client.loading)
        hasher.combine(client.presets.count)
        hasher.combine(client.commandData?.content)
        hasher.combine(client.info)
        hasher.combine(client.showHumanAgentBtn)
        return hasher.finalize()
    }
}

// MARK: - Chat Footer

private struct ChatFooter: View {
    let loading: Bool
    let isStreaming: Bool
    let info: String?
    let showHumanAgentBtn: Bool
    let commandData: CommandData?
    let presets: [String]
    let messagesCount: Int
    let botConfig: BotConfigProps
    let chatIcon: String?
    let locale: String
    let onSendMessage: (String) -> Void
    let onSendPreset: (String) -> Void
    let onSendCommandResponse: (String, Any) -> Void
    let onEndSession: () -> Void

    @Environment(\.rayaTheme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            // Typing indicator
            if loading && !isStreaming && info == nil {
                TypingIndicator(botIcon: chatIcon)
            }

            // Info display
            if let info {
                HStack(spacing: 8) {
                    AsyncImage(url: URL(string: "\(Constants.assetBaseURL)/animations/hourGlassAnimation.gif")) { image in
                        image.resizable().scaledToFit()
                    } placeholder: { EmptyView() }
                    .frame(width: 30, height: 30)

                    Text(info)
                        .font(RayaTypography.caption)
                        .foregroundColor(theme.foreground)
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 12)
            }

            // Escalation button
            if showHumanAgentBtn {
                HStack {
                    Spacer()
                    Button(action: { onSendMessage("/human_agent") }) {
                        Text(RayaStrings.get("connect_human", locale: locale))
                            .font(.system(size: 12))
                            .foregroundColor(theme.gradientColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(theme.gradientColor, lineWidth: 1.5))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 20)
            }

            // Command UIs
            if let cmd = commandData {
                switch cmd.content {
                case "rate_conversation":
                    RatingUI(message: cmd.message, options: cmd.options, botIcon: chatIcon, locale: locale) { rating in
                        onSendCommandResponse("rate_conversation", rating)
                    }
                case "submit_feedback":
                    FeedbackInput(message: cmd.message, optional: cmd.optional, botIcon: chatIcon, locale: locale) { text in
                        onSendCommandResponse("submit_feedback", text)
                    }
                case "feedback_received":
                    CountdownClose(message: cmd.message, botIcon: chatIcon, locale: locale, onComplete: onEndSession)
                case "end_session":
                    EndSessionUI(message: cmd.message, options: cmd.options, botIcon: chatIcon) { option in
                        onSendCommandResponse("end_session", option)
                    }
                default:
                    EmptyView()
                }
            }

            // Dynamic presets
            if !presets.isEmpty && commandData == nil {
                PresetButtons(presets: presets, onPress: onSendPreset)
            }

            // Static presets from config (only on first message)
            if let configPresets = botConfig.presetOptions, !configPresets.isEmpty, messagesCount == 1, commandData == nil {
                PresetButtons(presets: configPresets, onPress: onSendPreset)
            }
        }
    }
}
