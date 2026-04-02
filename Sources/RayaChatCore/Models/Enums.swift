import Foundation

/// Inbound WebSocket message types from the server.
public enum MessageType: String, Codable, Sendable {
    case step
    case chunk
    case response
    case presets
    case command
    case error
    case escalation
    case info
    case agentActivity = "agent_activity"
    case message
}

/// WebSocket connection status.
public enum ConnectionStatus: String, Sendable {
    case connecting
    case connected
    case disconnected
    case reconnecting
}

/// Current view in the chat widget.
public enum ViewMode: String, Sendable {
    case intro
    case form
    case chat
}

/// Reason the session was closed by the server.
public enum CloseReason: String, Sendable {
    case autoClose = "auto_close"
    case agentClose = "agent_close"
    case serverClose = "server_close"
}
