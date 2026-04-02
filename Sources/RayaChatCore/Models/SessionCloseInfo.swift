import Foundation

/// Information about a session closed by the server (e.g., auto_close due to inactivity).
public struct SessionCloseInfo: Equatable, Sendable {
    public let reason: CloseReason
    public let message: String

    public init(reason: CloseReason, message: String) {
        self.reason = reason
        self.message = message
    }
}
