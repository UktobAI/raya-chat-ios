import SwiftUI
import Combine
import RayaChatCore

/// ViewModel orchestrating the INTRO → FORM → CHAT state machine.
/// Wraps `RayaChatClient` and adds UI-specific state (viewMode, endChatModal, configLoading).
@MainActor
public final class RayaChatViewModel: ObservableObject {

    public let client: RayaChatClient

    @Published public var viewMode: ViewMode = .intro
    @Published public var showEndChatModal: Bool = false
    @Published public var botConfig: BotConfigProps = BotConfigProps()
    @Published public var isConfigLoading: Bool = true

    private var cancellables = Set<AnyCancellable>()

    public init(config: RayaChatConfig) {
        self.client = RayaChatClient(config: config)
    }

    // MARK: - Lifecycle

    /// Fetches bot configuration from API.
    public func loadConfig() async {
        isConfigLoading = true
        botConfig = await client.fetchBotConfig()
        isConfigLoading = false
    }

    // MARK: - Navigation

    /// Transitions from INTRO to FORM or CHAT.
    public func startChat() {
        guard viewMode == .intro else { return } // double-tap guard
        client.clearSessionCloseInfo()
        if botConfig.enableUserForm {
            viewMode = .form
        } else {
            viewMode = .chat
            connectWithEmptyUser()
        }
    }

    /// Transitions from FORM to CHAT after submitting user info.
    public func submitForm(userInfo: UserInfo) {
        viewMode = .chat
        Task {
            await client.connect(userInfo: userInfo, botConfig: botConfig)
        }
    }

    /// Shows the end chat confirmation modal.
    public func requestEndChat() {
        showEndChatModal = true
    }

    /// Cancels end chat — returns to CHAT.
    public func cancelEndChat() {
        showEndChatModal = false
    }

    /// Confirms end session — clears everything, back to INTRO.
    public func confirmEndSession() {
        showEndChatModal = false
        Task {
            await client.endSession()
            viewMode = .intro
        }
    }

    /// Goes back from FORM to INTRO.
    public func goBack() {
        if viewMode == .form {
            viewMode = .intro
        }
    }

    /// Called when user closes the widget.
    public func closeWidget() {
        client.config.onClose?()
    }

    // MARK: - Private

    private func connectWithEmptyUser() {
        Task {
            await client.connect(userInfo: UserInfo(), botConfig: botConfig)
        }
    }
}
