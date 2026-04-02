import Foundation

/// Audio data for voice messages.
public struct AudioData: Codable, Equatable, Sendable {
    public let type: String
    public let audioUrls: String

    enum CodingKeys: String, CodingKey {
        case type
        case audioUrls = "audio_urls"
    }

    public init(type: String = "", audioUrls: String = "") {
        self.type = type
        self.audioUrls = audioUrls
    }
}
