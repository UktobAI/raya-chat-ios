import Foundation
import Combine

/// Callbacks from the WebSocket manager to the client.
protocol WebSocketManagerCallbacks: AnyObject {
    func onMessage(_ text: String)
    func onOpen()
    func onClose(code: Int, reason: String)
    func onError(_ error: String)
}

/// Production-grade WebSocket manager using URLSessionWebSocketTask.
///
/// Features: heartbeat (25s/60s), exponential backoff reconnection (max 100, 30s cap),
/// message queue, destroyed flag, app state awareness.
final class WebSocketManager: @unchecked Sendable {

    weak var callbacks: WebSocketManagerCallbacks?

    private(set) var url: String = ""
    private var session: URLSession?
    private var task: URLSessionWebSocketTask?
    private var destroyed = false
    private var manualClose = false
    private var shouldNotReconnect = false
    private var reconnectAttempts = 0
    private var isAppActive = true
    private var hasNotifiedOpen = false

    private var heartbeatTask: Task<Void, Never>?
    private var heartbeatTimeoutTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var receiveTask: Task<Void, Never>?

    let messageQueue = MessageQueue()

    private let _status = CurrentValueSubject<ConnectionStatus, Never>(.disconnected)
    var status: AnyPublisher<ConnectionStatus, Never> { _status.eraseToAnyPublisher() }
    var currentStatus: ConnectionStatus { _status.value }

    // MARK: - Connect

    func connect(url: String) {
        guard !destroyed else { return }

        self.url = url
        manualClose = false
        shouldNotReconnect = false
        hasNotifiedOpen = false
        updateStatus(.connecting)

        guard let wsURL = URL(string: url) else {
            Log.e("WS", "→ CONNECT: Invalid URL")
            callbacks?.onError("Invalid WebSocket URL")
            return
        }

        Log.i("WS", "→ CONNECT: \(url.prefix(100))...[token redacted]")

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)
        task = session?.webSocketTask(with: wsURL)
        task?.resume()

        // Start receive loop — connection is confirmed on first successful receive
        startReceiving()

        // Send a ping immediately to trigger a pong — confirms connection faster.
        // URLSessionWebSocketTask buffers this until the handshake completes.
        task?.send(.string("ping")) { [weak self] error in
            if let error {
                Log.e("WS", "Initial ping failed: \(error.localizedDescription)")
            } else {
                Log.d("WS", "Initial ping sent successfully")
                // If ping succeeds, connection is open even if receive hasn't gotten anything yet
                guard let self, !self.hasNotifiedOpen else { return }
                self.hasNotifiedOpen = true
                Log.i("WS", "← OPEN (confirmed via successful ping send)")
                DispatchQueue.main.async {
                    self.reconnectAttempts = 0
                    self.updateStatus(.connected)
                    self.startHeartbeat()
                    self.flushQueue()
                    self.callbacks?.onOpen()
                }
            }
        }

        // Fallback: if still not connected after 10s, log diagnostic info
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            guard let self else { return }
            if !self.hasNotifiedOpen {
                Log.e("WS", "⚠️ CONNECTION TIMEOUT — still not open after 10s. Status: \(self._status.value), task: \(self.task != nil), destroyed: \(self.destroyed)")
            }
        }
    }

    // MARK: - Send

    func send(_ data: String) -> Bool {
        guard !destroyed else { return false }

        let logData = data.count > 500 ? "\(data.prefix(500))...[\(data.count) chars total]" : data
        Log.d("WS", "→ SEND (\(data.count) chars): \(logData)")

        if _status.value == .connected, let task = self.task {
            task.send(.string(data)) { error in
                if let error {
                    Log.e("WS", "→ SEND error: \(error.localizedDescription)")
                }
            }
            return true
        }

        // Queue if connecting
        if _status.value == .connecting {
            Log.d("WS", "→ QUEUED (connecting)")
            messageQueue.enqueue(data)
            return true
        }

        Log.w("WS", "→ SEND failed — not connected (status: \(_status.value))")
        return false
    }

    // MARK: - Update URL (for session ID changes)

    func updateUrl(_ newUrl: String) {
        self.url = newUrl
    }

    // MARK: - App State

    func setAppActive(_ active: Bool) {
        isAppActive = active
        if active {
            if _status.value == .connected {
                startHeartbeat()
                sendPing()
            } else {
                forceReconnect()
            }
        } else {
            stopHeartbeat()
        }
    }

    // MARK: - Destroy

    func destroy() {
        destroyed = true
        manualClose = true
        shouldNotReconnect = true
        stopHeartbeat()
        heartbeatTask?.cancel()
        heartbeatTimeoutTask?.cancel()
        reconnectTask?.cancel()
        receiveTask?.cancel()
        messageQueue.clear()
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        session?.invalidateAndCancel()
        session = nil
        updateStatus(.disconnected)
    }

    // MARK: - Receive Loop

    private func startReceiving() {
        receiveTask?.cancel()
        receiveTask = Task { [weak self] in
            guard let self else { return }

            while !self.destroyed && !Task.isCancelled {
                guard let currentTask = self.task else {
                    Log.w("WS", "← Receive loop: task is nil, breaking")
                    break
                }

                do {
                    let message = try await currentTask.receive()

                    // First successful receive = connection is open
                    if !self.hasNotifiedOpen {
                        self.hasNotifiedOpen = true
                        Log.i("WS", "← OPEN (first message received)")
                        await MainActor.run {
                            self.reconnectAttempts = 0
                            self.updateStatus(.connected)
                            self.startHeartbeat()
                            self.flushQueue()
                            self.callbacks?.onOpen()
                        }
                    }

                    switch message {
                    case .string(let text):
                        let logText = text.count > 300 ? "\(text.prefix(300))...[\(text.count) chars]" : text
                        Log.d("WS", "← RECV (\(text.count) chars): \(logText)")

                        if text == "pong" {
                            self.resetHeartbeatTimeout()
                        } else {
                            await MainActor.run {
                                self.callbacks?.onMessage(text)
                            }
                        }
                    case .data:
                        break
                    @unknown default:
                        break
                    }
                } catch {
                    guard !self.destroyed && !self.manualClose else { break }
                    Log.e("WS", "← RECV error: \(error.localizedDescription)")
                    await MainActor.run {
                        self.stopHeartbeat()
                        self.updateStatus(.disconnected)
                        self.callbacks?.onError(error.localizedDescription)
                        self.scheduleReconnect()
                    }
                    break
                }
            }
            Log.d("WS", "← Receive loop ended")
        }
    }

    // MARK: - Heartbeat

    private func startHeartbeat() {
        stopHeartbeat()
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(Constants.heartbeatInterval * 1_000_000_000))
                guard let self, !self.destroyed, self.isAppActive else { break }
                self.sendPing()
                self.startHeartbeatTimeout()
            }
        }
    }

    private func stopHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = nil
        heartbeatTimeoutTask?.cancel()
        heartbeatTimeoutTask = nil
    }

    private func sendPing() {
        task?.send(.string("ping")) { _ in }
    }

    private func startHeartbeatTimeout() {
        heartbeatTimeoutTask?.cancel()
        heartbeatTimeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Constants.heartbeatTimeout * 1_000_000_000))
            guard let self, !self.destroyed, !Task.isCancelled else { return }
            Log.w("WS", "← Heartbeat timeout — no pong in \(Constants.heartbeatTimeout)s")
            self.stopHeartbeat()
            // URLSessionWebSocketTask.CloseCode doesn't support custom codes (4000).
            // Use .goingAway (1001) — semantically correct: "endpoint is going away".
            self.task?.cancel(with: .goingAway, reason: "Heartbeat timeout".data(using: .utf8))
            self.task = nil
            await MainActor.run {
                self.scheduleReconnect()
            }
        }
    }

    private func resetHeartbeatTimeout() {
        heartbeatTimeoutTask?.cancel()
        heartbeatTimeoutTask = nil
    }

    // MARK: - Reconnection

    private func scheduleReconnect() {
        guard !destroyed && !shouldNotReconnect && !manualClose else { return }
        guard reconnectAttempts < Constants.maxReconnectAttempts else {
            Log.e("WS", "Max reconnect attempts (\(Constants.maxReconnectAttempts)) reached")
            callbacks?.onError("Connection lost. Please try again.")
            return
        }

        updateStatus(.reconnecting)

        // Exponential backoff with jitter — matches Android SDK and spec exactly:
        // delay = min(1000 * 2^attempt + random(0..1000), 30000) milliseconds
        let baseDelayMs = 1000.0 * pow(2.0, Double(reconnectAttempts))
        let jitterMs = Double.random(in: 0...1000)
        let delayMs = min(baseDelayMs + jitterMs, Constants.maxReconnectDelay * 1000)
        let delaySec = delayMs / 1000.0

        reconnectAttempts += 1 // increment AFTER calculating delay (matches Android)

        Log.i("WS", "Reconnecting in \(String(format: "%.1f", delaySec))s (attempt \(self.reconnectAttempts), jitter \(Int(jitterMs))ms)")

        reconnectTask?.cancel()
        reconnectTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delayMs * 1_000_000))
            guard let self, !self.destroyed, !Task.isCancelled else { return }
            self.task?.cancel(with: .normalClosure, reason: nil)
            self.task = nil
            self.connect(url: self.url)
        }
    }

    func forceReconnect() {
        guard !destroyed && !url.isEmpty else { return }
        reconnectAttempts = 0
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        connect(url: url)
    }

    // MARK: - Queue Flush

    private func flushQueue() {
        let queued = messageQueue.flushAll()
        Log.d("WS", "Flushing \(queued.count) queued messages")
        for msg in queued {
            _ = send(msg)
        }
    }

    // MARK: - Status

    private func updateStatus(_ status: ConnectionStatus) {
        _status.send(status)
    }
}
