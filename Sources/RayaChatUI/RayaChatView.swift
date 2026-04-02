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
    ///   - imagePickerAdapter: Adapter for image selection. Paperclip button hidden if nil.
    ///   - audioRecorderAdapter: Adapter for voice recording. Mic button hidden if nil.
    ///   - onSessionStart: Called with session ID when WebSocket connects.
    ///   - onSessionEnd: Called when session ends.
    ///   - onError: Called on connection/send errors.
    ///   - onClose: Called when user closes the widget.
    public init(
        token: String,
        locale: String = "en",
        imagePickerAdapter: (any ImagePickerAdapter)? = nil,
        audioRecorderAdapter: (any AudioRecorderAdapter)? = nil,
        onSessionStart: ((String) -> Void)? = nil,
        onSessionEnd: (() -> Void)? = nil,
        onError: ((String) -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        let config = RayaChatConfig(
            token: token,
            locale: locale,
            onSessionStart: onSessionStart,
            onSessionEnd: onSessionEnd,
            onError: onError,
            onClose: onClose
        )
        _viewModel = StateObject(wrappedValue: RayaChatViewModel(config: config))
        self.locale = locale
        self.imagePickerAdapter = imagePickerAdapter
        self.audioRecorderAdapter = audioRecorderAdapter
    }

    @StateObject private var viewModel: RayaChatViewModel
    private let locale: String
    private let imagePickerAdapter: (any ImagePickerAdapter)?
    private let audioRecorderAdapter: (any AudioRecorderAdapter)?

    public var body: some View {
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
                            onStartChat: { viewModel.startChat() },
                            onClose: { viewModel.closeWidget() }
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
                            onClose: { viewModel.requestEndChat() },
                            onEndSession: { viewModel.confirmEndSession() }
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
