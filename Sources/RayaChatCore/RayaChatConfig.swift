import Foundation

/// Configuration for the Raya Chat SDK.
///
/// Only `token` is required. All other fields have sensible defaults.
///
/// - Parameter token: Bot token from the Teammates.ai dashboard.
/// - Parameter locale: Language — `"en"` (English) or `"ar"` (Arabic/RTL). Default: `"en"`.
public struct RayaChatConfig {
    public let token: String
    public let locale: String
    public var onSessionStart: ((String) -> Void)?
    public var onSessionEnd: ((String, [TypeMessage]) -> Void)?
    public var onMessageUpdate: ((String, TypeMessage) -> Void)?
    public var onError: ((String) -> Void)?
    public var onClose: (() -> Void)?

    public init(
        token: String,
        locale: String = "en",
        onSessionStart: ((String) -> Void)? = nil,
        onSessionEnd: ((String, [TypeMessage]) -> Void)? = nil,
        onMessageUpdate: ((String, TypeMessage) -> Void)? = nil,
        onError: ((String) -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        self.token = token
        self.locale = locale
        self.onSessionStart = onSessionStart
        self.onSessionEnd = onSessionEnd
        self.onMessageUpdate = onMessageUpdate
        self.onError = onError
        self.onClose = onClose
    }
}
