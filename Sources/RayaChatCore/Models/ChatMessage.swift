import Foundation

/// Raw inbound WebSocket message before routing by type.
public struct ChatMessage: Codable, Sendable {
    public let type: String?
    public let text: String?
    public let content: String?
    public let presets: [String]?
    public let data: ChatResponseData?
    public let command: String?
    public let options: [AnyCodable]?
    public let message: String?
    public let optional: Bool?
    public let attachments: [String]?
    public let attachmentType: String?

    enum CodingKeys: String, CodingKey {
        case type, text, content, presets, data, command, options, message, optional
        case attachments, attachmentType = "attachment_type"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        presets = try container.decodeIfPresent([String].self, forKey: .presets)
        data = try container.decodeIfPresent(ChatResponseData.self, forKey: .data)
        command = try container.decodeIfPresent(String.self, forKey: .command)
        options = try container.decodeIfPresent([AnyCodable].self, forKey: .options)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        optional = try container.decodeIfPresent(Bool.self, forKey: .optional)
        attachments = try container.decodeIfPresent([String].self, forKey: .attachments)
        attachmentType = try container.decodeIfPresent(String.self, forKey: .attachmentType)
    }
}

/// Response data payload inside a RESPONSE message.
public struct ChatResponseData: Codable, Sendable {
    public let id: String?
    public let chatSessionId: String?
    public let sender: Int?
    public let content: String?
    public let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case chatSessionId = "chat_session_id"
        case sender, content
        case createdAt = "created_at"
    }
}

/// Type-erased Codable wrapper for heterogeneous arrays (e.g., command options).
/// Uses an enum internally so it's fully Sendable + Equatable.
public enum AnyCodable: Codable, Sendable, Equatable, CustomStringConvertible {
    case int(Int)
    case double(Double)
    case bool(Bool)
    case string(String)

    /// The underlying value as Any (for backward compatibility).
    public var value: Any {
        switch self {
        case .int(let v): return v
        case .double(let v): return v
        case .bool(let v): return v
        case .string(let v): return v
        }
    }

    public var description: String {
        switch self {
        case .int(let v): return "\(v)"
        case .double(let v): return "\(v)"
        case .bool(let v): return "\(v)"
        case .string(let v): return v
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            self = .int(intVal)
        } else if let doubleVal = try? container.decode(Double.self) {
            self = .double(doubleVal)
        } else if let boolVal = try? container.decode(Bool.self) {
            self = .bool(boolVal)
        } else if let stringVal = try? container.decode(String.self) {
            self = .string(stringVal)
        } else {
            self = .string("")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        case .string(let v): try container.encode(v)
        }
    }
}
