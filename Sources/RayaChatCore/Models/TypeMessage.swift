import Foundation

/// Chat message — the primary data type stored in Core Data and held in UI state.
///
/// Sender: 1 = user, 2 = bot/agent.
/// Type: 1 = text, 2 = audio, 3 = image, 4 = agent_activity/system.
public struct TypeMessage: Identifiable, Equatable, Sendable {
    public let id: String
    public let sender: Int
    public let type: Int
    public var content: String?
    public var createdAt: String?
    public var attachmentsJson: String?
    public var audioJson: String?

    public init(
        id: String,
        sender: Int,
        type: Int,
        content: String? = nil,
        createdAt: String? = nil,
        attachmentsJson: String? = nil,
        audioJson: String? = nil
    ) {
        self.id = id
        self.sender = sender
        self.type = type
        self.content = content
        self.createdAt = createdAt
        self.attachmentsJson = attachmentsJson
        self.audioJson = audioJson
    }

    /// Decode attachments from JSON string.
    public var attachments: [Attachment] {
        guard let json = attachmentsJson, let data = json.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([Attachment].self, from: data)) ?? []
    }

    /// Decode audio data from JSON string.
    public var audio: AudioData? {
        guard let json = audioJson, let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(AudioData.self, from: data)
    }
}
