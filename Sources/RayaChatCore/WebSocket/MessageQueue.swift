import Foundation

/// Thread-safe queue for messages sent while the WebSocket is in CONNECTING state.
/// Messages are flushed in order on successful connection.
final class MessageQueue: @unchecked Sendable {

    private var queue: [String] = []
    private let lock = NSLock()

    var isEmpty: Bool {
        lock.lock()
        defer { lock.unlock() }
        return queue.isEmpty
    }

    var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return queue.count
    }

    func enqueue(_ message: String) {
        lock.lock()
        defer { lock.unlock() }
        queue.append(message)
    }

    /// Drains the queue and returns all messages in FIFO order.
    func flushAll() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        let items = queue
        queue.removeAll()
        return items
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        queue.removeAll()
    }
}
