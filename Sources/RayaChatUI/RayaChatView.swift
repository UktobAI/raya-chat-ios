import SwiftUI
import RayaChatCore

/// Mode 1: SwiftUI View entry point — the simplest integration.
///
/// ```swift
/// RayaChatView(token: "your-bot-token")
/// ```
///
/// Manages its own `RayaChatViewModel` via `@StateObject` — survives SwiftUI view recreation.
public struct RayaChatView: View {

    /// Creates the chat widget.
    ///
    /// - Parameters:
    ///   - token: Bot token from the Teammates.ai dashboard.
    ///   - locale: Language — `"en"` (English) or `"ar"` (Arabic/RTL). Default: `"en"`.
    ///   - imagePickerAdapter: Adapter for image selection. Built-in PHPicker used if omitted. Pass nil to hide.
    ///   - audioRecorderAdapter: Adapter for voice recording. Built-in AVAudioRecorder used if omitted (when `NSMicrophoneUsageDescription` is present in Info.plist). Mic button hidden if nil and key is missing.
    ///   - audioPlayerAdapter: Adapter for audio playback. Built-in AVAudioPlayer used if omitted.
    ///   - onSessionStart: Called with session ID when WebSocket connects.
    ///   - onSessionEnd: Called when session ends — passes (sessionId, messages) with remote attachment URLs.
    ///   - onError: Called on connection/send errors.
    ///   - onClose: Called when user closes the widget.
    public init(
        token: String,
        locale: String = "en",
        imagePickerAdapter: (any ImagePickerAdapter)? = nil,
        audioRecorderAdapter: (any AudioRecorderAdapter)? = nil,
        audioPlayerAdapter: (any AudioPlayerAdapter)? = nil,
        onSessionStart: ((String) -> Void)? = nil,
        onSessionEnd: ((String, [TypeMessage]) -> Void)? = nil,
        onMessageUpdate: ((String, TypeMessage) -> Void)? = nil,
        onError: ((String) -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        let config = RayaChatConfig(
            token: token,
            locale: locale,
            onSessionStart: onSessionStart,
            onSessionEnd: onSessionEnd,
            onMessageUpdate: onMessageUpdate,
            onError: onError,
            onClose: onClose
        )
        _viewModel = StateObject(wrappedValue: RayaChatViewModel(config: config))
        self.locale = locale
        #if canImport(UIKit)
        self.imagePickerAdapter = imagePickerAdapter ?? DefaultImagePickerAdapter()
        #else
        self.imagePickerAdapter = imagePickerAdapter
        #endif
        // Audio recorder: developer-provided wins. Otherwise, auto-instantiate the
        // AVFoundation default — but only if the host app declared
        // NSMicrophoneUsageDescription. If absent, leave nil so the mic button
        // stays hidden and the app cannot crash.
        #if canImport(AVFAudio) && os(iOS)
        self.audioRecorderAdapter = audioRecorderAdapter ?? DefaultAudioRecorderAdapter.makeIfAvailable()
        self.audioPlayerAdapter = audioPlayerAdapter ?? DefaultAudioPlayerAdapter.make()
        #else
        self.audioRecorderAdapter = audioRecorderAdapter
        self.audioPlayerAdapter = audioPlayerAdapter
        #endif
    }

    @StateObject private var viewModel: RayaChatViewModel
    private let locale: String
    private let imagePickerAdapter: (any ImagePickerAdapter)?
    private let audioRecorderAdapter: (any AudioRecorderAdapter)?
    private let audioPlayerAdapter: (any AudioPlayerAdapter)?

    public var body: some View {
        // Theme is value type — only recalculated when botConfig or locale changes
        let theme = rayaThemeFrom(botConfig: viewModel.botConfig, locale: locale)

        ZStack {
            if viewModel.isConfigLoading {
                // Loading state
                theme.background.ignoresSafeArea()
                ProgressView()
                    .tint(theme.gradientColor)
            } else {
                // Main content
                Group {
                    switch viewModel.viewMode {
                    case .intro:
                        IntroScreen(
                            botConfig: viewModel.botConfig,
                            sessionCloseInfo: viewModel.client.sessionCloseInfo,
                            onStartChat: { viewModel.startChat() }
                        )

                    case .form:
                        FormScreen(
                            botConfig: viewModel.botConfig,
                            onSubmit: { userInfo in viewModel.submitForm(userInfo: userInfo) },
                            onBack: { viewModel.goBack() }
                        )

                    case .chat:
                        ChatScreen(
                            client: viewModel.client,
                            botConfig: viewModel.botConfig,
                            imagePickerAdapter: imagePickerAdapter,
                            audioRecorderAdapter: audioRecorderAdapter,
                            audioPlayerAdapter: audioPlayerAdapter,
                            onClose: { viewModel.closeChat() },
                            onEndSession: { viewModel.endSessionFromCommand() }
                        )
                    }
                }
                .environment(\.rayaTheme, theme)
                .environment(\.layoutDirection, theme.isRTL ? .rightToLeft : .leftToRight)

                // End chat modal
                if viewModel.showEndChatModal {
                    EndChatModal(
                        botIcon: viewModel.botConfig.chatboxChatIcon,
                        locale: locale,
                        onCancel: { viewModel.cancelEndChat() },
                        onEndSession: { viewModel.confirmEndSession() }
                    )
                    .environment(\.rayaTheme, theme)
                }
            }
        }
        .task {
            await viewModel.loadConfig()
        }
    }
}
