import Foundation
import Combine

/// Main entry point for the Raya Chat SDK.
///
/// Manages the entire chat lifecycle: WebSocket, heartbeat, reconnection, message persistence,
/// and all user actions. All state is published via `@Published` for reactive UI binding.
///
/// **Packaged UI** (Modes 1-3): Used internally by `RayaChatViewModel`.
/// **Headless** (Mode 4): Used directly by the host app.
public final class RayaChatClient: ObservableObject {

    // MARK: - Configuration

    public let config: RayaChatConfig

    // MARK: - Internal Components

    private let apiClient: APIClient
    private let keychainStorage = KeychainStorage()
    private let messageStore: MessageStore
    private let networkMonitor = NetworkMonitor()
    private let lifecycleObserver = AppLifecycleObserver()
    private var wsManager: WebSocketManager?
    private var messageHandler: MessageHandler?
    private var sessionId = ""
    private var currentUserInfo = UserInfo()
    private var cancellables = Set<AnyCancellable>()
    private var isConnecting = false
    private var isSessionEnding = false
    private var pendingAttachmentMessageIds: Set<String> = []

    private let json = JSONEncoder()

    // MARK: - Public State (@Published)

    @Published public var messages: [TypeMessage] = []
    @Published public var currentMessage: String = ""
    @Published public var connectionStatus: ConnectionStatus = .disconnected
    @Published public var isConnected: Bool = false
    @Published public var isOnline: Bool = true
    @Published public var loading: Bool = false
    @Published public var status: String? = nil
    @Published public var info: String? = nil
    @Published public var commandData: CommandData? = nil
    @Published public var presets: [String] = []
    @Published public var showHumanAgentBtn: Bool = false
    @Published public var sessionCloseInfo: SessionCloseInfo? = nil
    @Published public var currentSessionId: String = ""

    // MARK: - Init

    public init(config: RayaChatConfig) {
        self.config = config
        self.apiClient = APIClient(token: config.token, locale: config.locale)
        self.messageStore = MessageStore()

        setupNetworkMonitor()
        setupLifecycleObserver()
    }

    /// For testing with custom dependencies.
    init(config: RayaChatConfig, messageStore: MessageStore) {
        self.config = config
        self.apiClient = APIClient(token: config.token, locale: config.locale)
        self.messageStore = messageStore

        setupNetworkMonitor()
    }

    // MARK: - Public Actions

    /// Fetches bot configuration from the API.
    public func fetchBotConfig() async -> BotConfigProps {
        await apiClient.fetchBotConfig()
    }

    /// Starts the WebSocket connection.
    ///
    /// - Parameter userInfo: User details from the form (or empty for anonymous).
    /// - Parameter botConfig: Bot configuration — pass this so the initial bot message appears.
    @MainActor
    public func connect(userInfo: UserInfo, botConfig: BotConfigProps? = nil) async {
        guard !isConnecting else {
            Log.w("Client", "connect() already in progress — ignoring duplicate call")
            return
        }
        isConnecting = true
        defer { isConnecting = false }
        isSessionEnding = false

        do {
            try await connectInternal(userInfo: userInfo, botConfig: botConfig)
        } catch {
            Log.e("Client", "connect() failed: \(error.localizedDescription)")
            config.onError?("Connection failed: \(error.localizedDescription)")
        }
    }

    /// Sends a text message.
    @MainActor
    public func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let ts = Int(Date().timeIntervalSince1970)
        let msg = TypeMessage(
            id: "local-\(ts)-\(randomSuffix())",
            sender: 1,
            type: 1,
            content: trimmed,
            createdAt: "\(ts)"
        )

        addMessageToState(msg)
        presets = []

        let payload = OutboundMessage(content: trimmed, images: [])
        if let data = try? json.encode(payload), let jsonString = String(data: data, encoding: .utf8) {
            Log.i("Client", "sendMessage: wsManager=\(wsManager != nil), status=\(connectionStatus), json=\(jsonString.prefix(100))")
            let sent = wsManager?.send(jsonString) ?? false
            Log.i("Client", "sendMessage: sent=\(sent)")
            if !sent {
                config.onError?("Message queued — reconnecting...")
            }
        } else {
            Log.e("Client", "sendMessage: JSON encoding failed!")
        }
    }

    /// Sends images with an optional caption.
    @MainActor
    public func sendImages(_ images: [ImagePayload], caption: String = "") {
        let ts = Int(Date().timeIntervalSince1970)
        presets = []

        // Build local attachments JSON for display
        let localAttachments = images.enumerated().map { idx, img in
            Attachment(id: "local-att-\(ts)-\(idx)", url: img.uri.isEmpty ? img.base64 : img.uri, type: "image", name: img.name)
        }
        let attachmentsJson = (try? String(data: json.encode(localAttachments), encoding: .utf8)) ?? "[]"

        let msg = TypeMessage(
            id: "local-img-\(ts)-\(randomSuffix())",
            sender: 1,
            type: 3,
            content: caption,
            createdAt: "\(ts)",
            attachmentsJson: attachmentsJson
        )

        pendingAttachmentMessageIds.insert(msg.id) // Defer onMessageUpdate until remote URLs arrive
        addMessageToState(msg)

        // Heavy JSON serialization on background thread
        Task.detached { [weak self] in
            guard let self else { return }
            let outbound = OutboundMessage(
                content: caption,
                images: images.map { OutboundImage(name: $0.name, type: $0.type, data: $0.base64) }
            )
            do {
                let data = try self.json.encode(outbound)
                guard let jsonString = String(data: data, encoding: .utf8) else {
                    Log.e("Client", "sendImages: UTF8 encoding failed")
                    return
                }
                await MainActor.run {
                    let sent = self.wsManager?.send(jsonString) ?? false
                    if !sent {
                        self.config.onError?("Message queued — reconnecting...")
                    }
                }
            } catch {
                Log.e("Client", "sendImages encoding failed: \(error)")
                await MainActor.run {
                    self.config.onError?("Failed to send images — encoding error")
                }
            }
        }
    }

    /// Sends a voice note as base64.
    @MainActor
    public func sendAudio(_ base64: String) {
        let ts = Int(Date().timeIntervalSince1970)
        presets = []
        let audioData = AudioData(type: "local", audioUrls: base64)
        let audioJson = (try? String(data: json.encode(audioData), encoding: .utf8)) ?? "{}"

        let msg = TypeMessage(
            id: "local-audio-\(ts)-\(randomSuffix())",
            sender: 1,
            type: 2,
            content: "",
            createdAt: "\(ts)",
            audioJson: audioJson
        )

        pendingAttachmentMessageIds.insert(msg.id) // Defer onMessageUpdate until remote URL arrives
        addMessageToState(msg)

        let sent = wsManager?.send(base64) ?? false
        if !sent {
            config.onError?("Audio queued — reconnecting...")
        }
    }

    /// Sends a preset as a message and clears preset buttons.
    @MainActor
    public func sendPreset(_ text: String) {
        presets = []
        sendMessage(text)
    }

    /// Responds to a server command.
    @MainActor
    public func sendCommandResponse(command: String, response: Any) {
        commandData = nil
        presets = [] // Clear presets alongside commandData to prevent flash between command transitions

        let responseString = "\(response)"
        let cmd = OutboundCommandResponse(command: command, response: responseString)
        if let data = try? json.encode(cmd), let jsonString = String(data: data, encoding: .utf8) {
            _ = wsManager?.send(jsonString)
        }
    }

    /// Clears the session close info (after auto_close warning).
    @MainActor
    public func clearSessionCloseInfo() {
        sessionCloseInfo = nil
    }

    /// Ends the current session — clears all storage and state.
    @MainActor
    public func endSession() async {
        // 0. Capture session data BEFORE clearing (for onSessionEnd callback)
        let finalSessionId = currentSessionId
        let finalMessages = messages

        // 0b. Block all delegate callbacks during teardown
        isSessionEnding = true

        // 1. Destroy WebSocket + block reconnection
        wsManager?.destroy()
        wsManager = nil

        // 2. Stop lifecycle observer (prevents callbacks during/after cleanup)
        lifecycleObserver.stop()

        // 3. Stop network monitor
        networkMonitor.stop()

        // 4. Cancel all Combine subscriptions (prevents stale state updates)
        cancellables.removeAll()

        // 5. Clear identity + pending state
        sessionId = ""
        currentSessionId = ""
        currentUserInfo = UserInfo()
        pendingAttachmentMessageIds.removeAll()

        // 6. Clear storage on background
        await Task.detached { [messageStore = self.messageStore, keychain = self.keychainStorage] in
            messageStore.deleteAll()
            keychain.clearAll()
        }.value

        // 7. Reset ALL state (matches Android exactly)
        messages = []
        currentMessage = ""
        connectionStatus = .disconnected
        isConnected = false
        loading = false
        status = nil
        info = nil
        commandData = nil
        presets = []
        showHumanAgentBtn = false
        sessionCloseInfo = nil // Fix: clear stale warning — prevents "Session closed" banner on next Intro

        // 8. Fire callback with captured session data (remote URLs already in messages via onAttachments)
        Log.i("Client", "onSessionEnd — sessionId: \(finalSessionId)")
        Log.i("Client", "onSessionEnd — \(finalMessages.count) messages:")
        for (i, msg) in finalMessages.enumerated() {
            let sender = msg.sender == 1 ? "USER" : (msg.sender == 2 ? "BOT" : "SYSTEM")
            Log.i("Client", "  [\(i)] \(sender) id=\(msg.id) type=\(msg.type) createdAt=\(msg.createdAt ?? "nil")")
            Log.i("Client", "       content: \(msg.content ?? "(nil)")")
            if let attsJson = msg.attachmentsJson {
                Log.i("Client", "       attachmentsJson: \(attsJson)")
            }
            if let audioJson = msg.audioJson {
                Log.i("Client", "       audioJson: \(audioJson)")
            }
        }
        config.onSessionEnd?(finalSessionId, finalMessages)
        Log.i("Client", "Session ended — all state cleared")
    }

    /// Releases all resources. Call on Activity/ViewController destroy.
    public func destroy() {
        wsManager?.destroy()
        wsManager = nil
        networkMonitor.stop()
        lifecycleObserver.stop()
        cancellables.removeAll()
        Log.i("Client", "Client destroyed")
    }

    // MARK: - Private — Connect

    @MainActor
    private func connectInternal(userInfo: UserInfo, botConfig: BotConfigProps?) async throws {
        currentUserInfo = userInfo

        // Re-start monitors (may have been stopped by endSession)
        setupNetworkMonitor()
        setupLifecycleObserver()

        // Restore session ID + messages on background
        let (restoredId, storedMessages) = await Task.detached { [keychain = self.keychainStorage, store = self.messageStore] () -> (String, [TypeMessage]) in
            let sid = keychain.getSessionId()
            let msgs = store.getAll()
            keychain.setUserInfo(userInfo)
            return (sid, msgs)
        }.value

        sessionId = restoredId
        currentSessionId = restoredId
        messages = storedMessages

        // Add initial bot message if no stored messages
        if storedMessages.isEmpty, let botConfig {
            let initialMsg = botConfig.chatboxInitialMsg ?? ""
            if !initialMsg.isEmpty {
                let welcomeMsg = TypeMessage(
                    id: "initial-\(Int(Date().timeIntervalSince1970))",
                    sender: 2,
                    type: 1,
                    content: initialMsg,
                    createdAt: "\(Int(Date().timeIntervalSince1970))"
                )
                addMessageToState(welcomeMsg)
            }
        }

        // Setup WebSocket
        let handler = MessageHandler()
        handler.delegate = self
        messageHandler = handler
        Log.i("Client", "connectInternal: messageHandler set, delegate=\(handler.delegate != nil)")

        let ws = WebSocketManager()
        ws.callbacks = self
        wsManager = ws
        Log.i("Client", "connectInternal: wsManager set, callbacks=\(ws.callbacks != nil)")

        // Observe connection status
        ws.status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                Log.i("Client", "Connection status changed: \(status)")
                self?.connectionStatus = status
                self?.isConnected = (status == .connected)
            }
            .store(in: &cancellables)

        // Connect
        let url = apiClient.constructWebSocketUrl(sessionId: sessionId, userInfo: userInfo)
        Log.i("Client", "connectInternal: WS URL = \(url.prefix(150))...")
        ws.connect(url: url)
    }

    // MARK: - Private — Setup

    private func setupNetworkMonitor() {
        networkMonitor.isOnline
            .receive(on: DispatchQueue.main)
            .sink { [weak self] online in
                self?.isOnline = online
            }
            .store(in: &cancellables)
        networkMonitor.start()
    }

    private func setupLifecycleObserver() {
        lifecycleObserver.onForeground = { [weak self] duration in
            guard let self else { return }
            if duration > Constants.staleStateThreshold {
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.currentMessage = ""
                    self.loading = false
                    self.status = nil
                }
            }
            self.wsManager?.setAppActive(true)
        }
        lifecycleObserver.onBackground = { [weak self] in
            self?.wsManager?.setAppActive(false)
        }
        lifecycleObserver.start()
    }

    // MARK: - Private — State Helpers

    @MainActor
    private func addMessageToState(_ message: TypeMessage) {
        messages.append(message)

        // Trim in-memory
        if messages.count > Constants.maxMessagesInMemory {
            messages = Array(messages.suffix(Constants.maxMessagesInMemory))
        }

        // Persist on background
        Task.detached { [store = self.messageStore] in
            store.insert(message)
            store.trimToLatest()
        }

        // Fire onMessageUpdate — skip pending image/audio messages (they fire after remote URLs arrive)
        if !pendingAttachmentMessageIds.contains(message.id) {
            config.onMessageUpdate?(currentSessionId, message)
        }
    }

    private func randomSuffix() -> String {
        UUID().uuidString.prefix(8).lowercased()
    }
}

// MARK: - WebSocketManagerCallbacks

extension RayaChatClient: WebSocketManagerCallbacks {
    func onMessage(_ text: String) {
        Log.d("Client", "onMessage received, handler exists: \(messageHandler != nil)")
        messageHandler?.handle(text)
    }

    func onOpen() {
        Log.i("Client", "WebSocket opened")
        if !sessionId.isEmpty {
            config.onSessionStart?(sessionId)
        }
    }

    func onClose(code: Int, reason: String) {
        Log.i("Client", "WebSocket closed: \(code) \(reason)")
    }

    func onError(_ error: String) {
        Log.e("Client", "WebSocket error: \(error)")
        config.onError?(error)
    }
}

// MARK: - MessageHandlerDelegate

extension RayaChatClient: MessageHandlerDelegate {

    /// Safely dispatch state update — skips if session is ending (prevents stale callbacks).
    private func safeMainActor(_ block: @MainActor @escaping () -> Void) {
        Task { @MainActor [weak self] in
            guard let self, !self.isSessionEnding else { return }
            block()
        }
    }

    func onStep(text: String?) {
        Log.d("Client", "onStep: \(text ?? "nil")")
        safeMainActor {
            self.loading = true
            self.status = text
        }
    }

    func onChunk(text: String) {
        Log.d("Client", "onChunk: \(text.prefix(50))")
        safeMainActor {
            self.currentMessage += text
            self.loading = false
            self.status = nil
        }
    }

    func onResponse(message: TypeMessage, sessionId: String?) {
        Log.i("Client", "onResponse: id=\(message.id), content=\(message.content?.prefix(50) ?? "nil"), createdAt=\(message.createdAt ?? "nil")")
        safeMainActor {
            if !self.currentMessage.isEmpty {
                let finalMsg = TypeMessage(
                    id: message.id,
                    sender: 2,
                    type: 1,
                    content: self.currentMessage,
                    createdAt: message.createdAt
                )
                self.addMessageToState(finalMsg)
                self.currentMessage = ""
            } else if let content = message.content, !content.isEmpty {
                self.addMessageToState(message)
            }
            self.loading = false
            self.status = nil
            self.info = nil
        }
    }

    func onPresets(_ newPresets: [String]) {
        Log.i("Client", "onPresets: \(newPresets)")
        safeMainActor { self.presets = newPresets }
    }

    func onCommand(data: CommandData) {
        safeMainActor {
            self.presets = []
            self.commandData = data
            self.loading = false
            self.status = nil
        }
    }

    func onError(text: String) {
        safeMainActor {
            let errorMsg = TypeMessage(
                id: "error-\(Int(Date().timeIntervalSince1970))-\(self.randomSuffix())",
                sender: 2, type: 1, content: text,
                createdAt: "\(Int(Date().timeIntervalSince1970))"
            )
            self.addMessageToState(errorMsg)
            self.loading = false
            self.status = nil
            self.currentMessage = ""
        }
    }

    func onAutoClose(info: SessionCloseInfo) {
        Log.i("Client", "onAutoClose: \(info.message)")
        safeMainActor {
            self.sessionCloseInfo = info
            self.presets = []
            self.wsManager?.destroy()
            self.wsManager = nil
            self.loading = false
            self.status = nil
            self.currentMessage = ""
        }
    }

    func onEscalation(showButton: Bool) {
        safeMainActor { self.showHumanAgentBtn = showButton }
    }

    func onInfo(text: String?) {
        safeMainActor {
            self.info = text
            self.loading = text != nil
        }
    }

    func onAgentActivity(message: TypeMessage) {
        safeMainActor { self.addMessageToState(message) }
    }

    func onServerMessage(message: TypeMessage) {
        safeMainActor { self.addMessageToState(message) }
    }

    func onSessionUpdate(sessionId: String) {
        safeMainActor {
            self.sessionId = sessionId
            self.currentSessionId = sessionId
        }

        // Persist + update URL on background
        Task.detached { [keychain = self.keychainStorage, apiClient = self.apiClient, userInfo = self.currentUserInfo] in
            keychain.setSessionId(sessionId)
            let newUrl = apiClient.constructWebSocketUrl(sessionId: sessionId, userInfo: userInfo)
            await MainActor.run { [weak self] in
                self?.wsManager?.updateUrl(newUrl)
            }
        }

        Log.i("Client", "Session ID updated: \(sessionId) — WS URL refreshed")
    }

    func onAttachments(attachments: [String], type: String) {
        // Find the target message on MainActor first (last user message matching type)
        safeMainActor {
            let targetType = type == "image" ? 3 : (type == "audio" ? 2 : 0)
            guard let idx = self.messages.lastIndex(where: { $0.sender == 1 && $0.type == targetType }) else {
                Log.w("Client", "onAttachments: no matching user message found for type=\(type)")
                return
            }
            let targetMsg = self.messages[idx]

            Task.detached { [store = self.messageStore, json = self.json] in
                var updated: TypeMessage?

                if type == "image" && !attachments.isEmpty {
                    // Preserve original id/name from local message, only update URL
                    let originalAtts = targetMsg.attachments
                    let atts = attachments.enumerated().map { idx, url -> Attachment in
                        let original = originalAtts.indices.contains(idx) ? originalAtts[idx] : nil
                        return Attachment(
                            id: original?.id ?? "",
                            url: url,
                            type: "image",
                            name: original?.name ?? ""
                        )
                    }
                    if let data = try? json.encode(atts), let jsonStr = String(data: data, encoding: .utf8) {
                        updated = TypeMessage(
                            id: targetMsg.id, sender: targetMsg.sender, type: targetMsg.type,
                            content: targetMsg.content, createdAt: targetMsg.createdAt,
                            attachmentsJson: jsonStr, audioJson: targetMsg.audioJson
                        )
                    }
                } else if type == "audio" && !attachments.isEmpty {
                    let audioData = AudioData(type: "remote", audioUrls: attachments.first ?? "")
                    if let data = try? json.encode(audioData), let jsonStr = String(data: data, encoding: .utf8) {
                        updated = TypeMessage(
                            id: targetMsg.id, sender: targetMsg.sender, type: targetMsg.type,
                            content: targetMsg.content, createdAt: targetMsg.createdAt,
                            attachmentsJson: targetMsg.attachmentsJson, audioJson: jsonStr
                        )
                    }
                }

                if let updated {
                    store.insert(updated)
                    Log.i("Client", "onAttachments: updated message \(updated.id) with remote \(type) URLs")
                    await MainActor.run { [weak self] in
                        guard let self else { return }
                        if let idx = self.messages.firstIndex(where: { $0.id == updated.id }) {
                            self.messages[idx] = updated
                        }
                        // Fire deferred onMessageUpdate now that URLs are remote
                        self.pendingAttachmentMessageIds.remove(updated.id)
                        self.config.onMessageUpdate?(self.currentSessionId, updated)
                    }
                }
            }
        }
    }
}
