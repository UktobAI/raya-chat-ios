import Foundation

/// Outbound text/image message sent via WebSocket.
public struct OutboundMessage: Codable, Sendable {
    public let content: String
    public let images: [OutboundImage]

    public init(content: String, images: [OutboundImage] = []) {
        self.content = content
        self.images = images
    }
}

/// Single image in an outbound message.
public struct OutboundImage: Codable, Sendable {
    public let name: String
    public let type: String
    public let data: String

    public init(name: String, type: String, data: String) {
        self.name = name
        self.type = type
        self.data = data
    }
}

/// Outbound command response.
public struct OutboundCommandResponse: Codable, Sendable {
    public let type: String
    public let command: String
    public let response: String

    public init(type: String = "command_response", command: String, response: String) {
        self.type = type
        self.command = command
        self.response = response
    }
}

/// Payload for sending images — passed by the host app.
public struct ImagePayload: Sendable {
    public let name: String
    public let type: String
    public let base64: String
    public let uri: String

    public init(name: String, type: String, base64: String, uri: String = "") {
        self.name = name
        self.type = type
        self.base64 = base64
        self.uri = uri
    }
}
