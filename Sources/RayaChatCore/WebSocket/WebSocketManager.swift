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

        // Start receive loop
        startReceiving()

        // URLSessionWebSocketTask doesn't have a delegate callback for "open"
        // The first successful receive or send indicates the connection is open.
        // We'll trigger onOpen from the first successful operation.
        // For now, optimistically mark as connected after a brief delay.
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard let self, !self.destroyed, self._status.value == .connecting else { return }
            self.updateStatus(.connected)
            self.reconnectAttempts = 0
            self.startHeartbeat()
            self.flushQueue()
            self.callbacks?.onOpen()
        }
    }

    // MARK: - Send

    func send(_ data: String) -> Bool {
        guard !destroyed else { return false }

        let logData = data.count > 500 ? "\(data.prefix(500))...[\(data.count) chars total]" : data
        Log.d("WS", "→ SEND (\(data.count) chars): \(logData)")

        if _status.value == .connected {
            task?.send(.string(data)) { [weak self] error in
                if let error {
                    Log.e("WS", "→ SEND error: \(error.localizedDescription)")
                    self?.callbacks?.onError("Send failed: \(error.localizedDescription)")
                }
            }
            return true
        }

        // Queue if connecting
        if _status.value == .connecting {
            messageQueue.enqueue(data)
            return true
        }

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
                do {
                    guard let message = try await self.task?.receive() else { break }
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
                        break // We don't handle binary
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
        }
    }

    // MARK: - Heartbeat

    private func startHeartbeat() {
        stopHeartbeat()
        heartbeatTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Constants.heartbeatInterval))
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
            try? await Task.sleep(for: .seconds(Constants.heartbeatTimeout))
            guard let self, !self.destroyed, !Task.isCancelled else { return }
            // No pong received — connection is dead
            Log.w("WS", "← Heartbeat timeout — no pong in \(Constants.heartbeatTimeout)s")
            self.stopHeartbeat()
            if let closeCode = URLSessionWebSocketTask.CloseCode(rawValue: Constants.wsCloseHeartbeatTimeout) {
                self.task?.cancel(with: closeCode, reason: "Heartbeat timeout".data(using: .utf8))
            } else {
                self.task?.cancel(with: .abnormalClosure, reason: "Heartbeat timeout".data(using: .utf8))
            }
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
        reconnectAttempts += 1

        let delay = min(
            pow(2.0, Double(reconnectAttempts)) * 0.5,
            Constants.maxReconnectDelay
        )
        Log.i("WS", "Reconnecting in \(delay)s (attempt \(self.reconnectAttempts))")

        reconnectTask?.cancel()
        reconnectTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
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
        for msg in queued {
            _ = send(msg)
        }
    }

    // MARK: - Status

    private func updateStatus(_ status: ConnectionStatus) {
        _status.send(status)
    }
}
