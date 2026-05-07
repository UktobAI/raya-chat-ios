import Foundation

/// SDK-wide constants matching the React Native SDK v0.1.0.
public enum Constants {
    public static let sdkVersion = "0.1.2"
    public static let defaultEndpoint = "api.workforce.uktob.ai"
    public static let integrationType = "widget"
    public static let defaultBotAvatar = "https://app.teammates.ai/api/assets/images/New_raya_agent.png"
    public static let assetBaseURL = "https://app.teammates.ai/api/assets"

    // WebSocket
    public static let heartbeatInterval: TimeInterval = 25
    public static let heartbeatTimeout: TimeInterval = 60
    public static let maxReconnectAttempts = 100
    public static let maxReconnectDelay: TimeInterval = 30
    public static let staleStateThreshold: TimeInterval = 60

    // WebSocket close codes
    public static let wsCloseNormal = 1000
    public static let wsCloseGoingAway = 1001
    public static let wsCloseHeartbeatTimeout = 4000

    // Storage
    public static let maxMessagesInMemory = 500
    public static let maxImagesPerMessage = 5
    public static let maxFeedbackLength = 200
    public static let feedbackCountdownSeconds = 3

    // Audio
    public static let maxAudioDurationSeconds = 180            // 3 min hard cap (WAV is ~10x bigger than AAC)
    public static let maxAudioPayloadBytes = 10 * 1024 * 1024  // 10 MB — fits 3 min WAV PCM 16k mono base64
    public static let minAudioPayloadBytes = 4096              // <4KB rejected (under ~125ms — Whisper would discard anyway)

    // Storage keys
    public static let sessionIdKey = "raya-chat-session-id"
    public static let userInfoKey = "raya-chat-user"
    public static let keychainService = "ai.teammates.rayachat"

    // Core Data
    public static let coreDataModelName = "RayaChat"
    public static let messagesEntityName = "MessageEntity"

    // Valid server commands
    public static let validCommands = [
        "end_session",
        "rate_conversation",
        "submit_feedback",
        "feedback_received",
        "auto_close",
    ]
}
