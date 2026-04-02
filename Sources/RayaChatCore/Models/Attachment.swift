import Foundation

/// Image/file attachment in a message.
public struct Attachment: Codable, Equatable, Sendable {
    public let id: String
    public let url: String
    public let type: String
    public let name: String

    public init(id: String = "", url: String = "", type: String = "image", name: String = "") {
        self.id = id
        self.url = url
        self.type = type
        self.name = name
    }
}
