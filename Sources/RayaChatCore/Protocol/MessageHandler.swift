import Foundation

/// Routes incoming WebSocket messages by type to the appropriate delegate callback.
/// Handles all 10 inbound message types defined in NATIVE_SDK_SPEC.md.
final class MessageHandler {

    weak var delegate: MessageHandlerDelegate?

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .useDefaultKeys
        return d
    }()

    /// Parse and route a raw WebSocket text message.
    func handle(_ text: String) {
        guard let data = text.data(using: .utf8) else {
            Log.e("Protocol", "Failed to convert message to data")
            return
        }

        let chatMessage: ChatMessage
        do {
            chatMessage = try decoder.decode(ChatMessage.self, from: data)
        } catch {
            Log.e("Protocol", "Failed to decode message: \(error.localizedDescription)")
            return
        }

        guard let typeString = chatMessage.type else {
            Log.w("Protocol", "Message has no type field")
            return
        }

        guard let messageType = MessageType(rawValue: typeString) else {
            Log.w("Protocol", "Unknown message type: \(typeString)")
            return
        }

        switch messageType {
        case .step:
            handleStep(chatMessage)
        case .chunk:
            handleChunk(chatMessage)
        case .response:
            handleResponse(chatMessage)
        case .presets:
            handlePresets(chatMessage)
        case .command:
            handleCommand(chatMessage)
        case .error:
            handleError(chatMessage)
        case .escalation:
            handleEscalation(chatMessage)
        case .info:
            handleInfo(chatMessage)
        case .agentActivity:
            handleAgentActivity(chatMessage)
        case .message:
            handleMessage(chatMessage)
        }
    }

    // MARK: - Type Handlers

    private func handleStep(_ msg: ChatMessage) {
        delegate?.onStep(text: msg.text)
    }

    private func handleChunk(_ msg: ChatMessage) {
        let chunkText = msg.text ?? msg.content ?? ""
        guard !chunkText.isEmpty else { return }
        delegate?.onChunk(text: chunkText)
    }

    private func handleResponse(_ msg: ChatMessage) {
        guard let responseData = msg.data else {
            Log.w("Protocol", "RESPONSE missing data field")
            return
        }

        // Update session ID
        if let sessionId = responseData.chatSessionId, !sessionId.isEmpty {
            delegate?.onSessionUpdate(sessionId: sessionId)
        }

        // Build TypeMessage from response
        let ts = responseData.createdAt ?? "\(Int(Date().timeIntervalSince1970))"
        let typeMessage = TypeMessage(
            id: responseData.id ?? UUID().uuidString,
            sender: responseData.sender ?? 2,
            type: 1,
            content: responseData.content,
            createdAt: ts
        )

        delegate?.onResponse(message: typeMessage, sessionId: responseData.chatSessionId)

        // Handle attachments if present
        if let attachments = msg.attachments, !attachments.isEmpty {
            let attType = msg.attachmentType ?? "image"
            delegate?.onAttachments(attachments: attachments, type: attType)
        }
    }

    private func handlePresets(_ msg: ChatMessage) {
        let presets = msg.presets ?? []
        delegate?.onPresets(presets)
    }

    private func handleCommand(_ msg: ChatMessage) {
        let content = msg.content ?? msg.command ?? ""
        guard Constants.validCommands.contains(content) else {
            Log.w("Protocol", "Invalid command: \(content)")
            return
        }

        // Handle auto_close specially
        if content == "auto_close" {
            let closeMsg = msg.message ?? "Session closed due to inactivity."
            let errorText = sanitizeErrorMessage(closeMsg)
            delegate?.onError(text: errorText)
            return
        }

        let options = msg.options ?? []
        let commandData = CommandData(
            content: content,
            options: options,
            message: msg.message ?? "",
            optional: msg.optional ?? false
        )
        delegate?.onCommand(data: commandData)
    }

    private func handleError(_ msg: ChatMessage) {
        let errorText = msg.text ?? msg.content ?? "Unknown error"
        let sanitized = sanitizeErrorMessage(errorText)
        delegate?.onError(text: sanitized)
    }

    private func handleEscalation(_ msg: ChatMessage) {
        delegate?.onEscalation(showButton: true)
    }

    private func handleInfo(_ msg: ChatMessage) {
        delegate?.onInfo(text: msg.text)
    }

    private func handleAgentActivity(_ msg: ChatMessage) {
        let content = msg.text ?? msg.content ?? ""
        let typeMessage = TypeMessage(
            id: UUID().uuidString,
            sender: 2,
            type: 4,
            content: content,
            createdAt: "\(Int(Date().timeIntervalSince1970))"
        )
        delegate?.onAgentActivity(message: typeMessage)
    }

    private func handleMessage(_ msg: ChatMessage) {
        let content = msg.text ?? msg.content ?? ""
        let typeMessage = TypeMessage(
            id: UUID().uuidString,
            sender: 2,
            type: 1,
            content: content,
            createdAt: "\(Int(Date().timeIntervalSince1970))"
        )
        delegate?.onServerMessage(message: typeMessage)
    }
}
