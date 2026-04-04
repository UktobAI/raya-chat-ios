import SwiftUI
import Combine
import RayaChatCore

/// ViewModel orchestrating the INTRO → FORM → CHAT state machine.
/// Matches Android RayaChatViewModel.kt exactly.
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

    // Cleanup when ViewModel is destroyed — matches Android onCleared()
    deinit {
        client.destroy()
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
        guard viewMode == .intro else { return }
        client.clearSessionCloseInfo()
        if botConfig.enableUserForm {
            viewMode = .form
        } else {
            // Skip form — connect then switch to chat (matches Android order)
            Task {
                await client.connect(userInfo: UserInfo(), botConfig: botConfig)
                viewMode = .chat
            }
        }
    }

    /// Connects with user info, then transitions to CHAT.
    /// Order: connect FIRST → viewMode AFTER (matches Android submitForm).
    public func submitForm(userInfo: UserInfo) {
        Task {
            await client.connect(userInfo: userInfo, botConfig: botConfig)
            viewMode = .chat
        }
    }

    /// Close button behavior — matches Android closeChat().
    /// On CHAT: shows end chat confirmation modal.
    /// On other screens: goes back to INTRO.
    public func closeChat() {
        if viewMode == .chat {
            showEndChatModal = true
        } else {
            viewMode = .intro
        }
    }

    /// Cancels end chat — returns to CHAT.
    public func cancelEndChat() {
        showEndChatModal = false
    }

    /// Confirms end session — clears everything, back to INTRO.
    public func confirmEndSession() {
        Task {
            showEndChatModal = false
            await client.endSession()
            viewMode = .intro
        }
    }

    /// End session triggered by server command (feedback_received countdown).
    public func endSessionFromCommand() {
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
}
