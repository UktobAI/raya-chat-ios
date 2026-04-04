import Foundation

/// Callbacks from the message handler to the client.
/// Each method corresponds to a server message type's required action.
protocol MessageHandlerDelegate: AnyObject {
    /// STEP — bot is processing. Set loading = true, update status text.
    func onStep(text: String?)

    /// CHUNK — partial bot response. Append to currentMessage.
    func onChunk(text: String)

    /// RESPONSE — complete bot message. Add to messages, clear streaming, update session ID.
    func onResponse(message: TypeMessage, sessionId: String?)

    /// PRESETS — suggestion buttons from server.
    func onPresets(_ presets: [String])

    /// COMMAND — server command requiring user interaction.
    func onCommand(data: CommandData)

    /// ERROR — server-side error.
    func onError(text: String)

    /// AUTO_CLOSE — session closed by server due to inactivity.
    func onAutoClose(info: SessionCloseInfo)

    /// ESCALATION — human agent connected.
    func onEscalation(showButton: Bool)

    /// INFO — status message (e.g., "Waiting for human agent...").
    func onInfo(text: String?)

    /// AGENT_ACTIVITY — agent join/leave notification.
    func onAgentActivity(message: TypeMessage)

    /// MESSAGE — generic text message from server.
    func onServerMessage(message: TypeMessage)

    /// Session ID updated from RESPONSE data.
    func onSessionUpdate(sessionId: String)

    /// Attachments received (image URLs or audio URLs from server for the last bot message).
    func onAttachments(attachments: [String], type: String)
}
