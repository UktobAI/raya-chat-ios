import Foundation

/// Raw inbound WebSocket message before routing by type.
/// All fields are decoded leniently — type mismatches are handled gracefully.
public struct ChatMessage: Codable, Sendable {
    public let type: String?
    public let text: String?
    public let content: String?
    public let presets: [PresetItem]?
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

        // Presets: server sends [{id, title, prompt, ...}] — decode as PresetItem objects
        presets = try? container.decodeIfPresent([PresetItem].self, forKey: .presets)

        // Data: decode leniently — if it fails, just nil
        data = try? container.decodeIfPresent(ChatResponseData.self, forKey: .data)

        command = try container.decodeIfPresent(String.self, forKey: .command)

        // Options: can be mixed types — decode leniently
        options = try? container.decodeIfPresent([AnyCodable].self, forKey: .options)

        message = try container.decodeIfPresent(String.self, forKey: .message)
        optional = try? container.decodeIfPresent(Bool.self, forKey: .optional)
        attachments = try? container.decodeIfPresent([String].self, forKey: .attachments)
        attachmentType = try container.decodeIfPresent(String.self, forKey: .attachmentType)
    }
}

/// Preset item from the server — has id, title, prompt, etc.
/// We extract `title` for display (matches Android's PresetItem).
public struct PresetItem: Codable, Sendable {
    public let id: String?
    public let title: String?
    public let prompt: String?
    public let category: String?
    public let confidence: Double?

    public init(id: String? = nil, title: String? = nil, prompt: String? = nil, category: String? = nil, confidence: Double? = nil) {
        self.id = id
        self.title = title
        self.prompt = prompt
        self.category = category
        self.confidence = confidence
    }
}

/// Response data payload inside a RESPONSE message.
/// `created_at` can be either a number (Long) or a string — handle both.
public struct ChatResponseData: Codable, Sendable {
    public let id: String?
    public let chatSessionId: String?
    public let sender: Int?
    public let content: String?
    public let createdAt: String? // Stored as string, decoded from either string or number
    public let attachments: [String]?
    public let attachmentType: String?
    public let audioUrls: String? // Remote S3 URL for the user's voice note, returned after upload

    enum CodingKeys: String, CodingKey {
        case id
        case chatSessionId = "chat_session_id"
        case sender, content
        case createdAt = "created_at"
        case attachments
        case attachmentType = "attachment_type"
        case audioUrls = "audio_urls"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        chatSessionId = try container.decodeIfPresent(String.self, forKey: .chatSessionId)
        sender = try? container.decodeIfPresent(Int.self, forKey: .sender)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        attachments = try? container.decodeIfPresent([String].self, forKey: .attachments)
        attachmentType = try? container.decodeIfPresent(String.self, forKey: .attachmentType)
        audioUrls = try? container.decodeIfPresent(String.self, forKey: .audioUrls)

        // created_at: server sends as Long (number) — Android uses Long, we convert to String
        if let intValue = try? container.decodeIfPresent(Int64.self, forKey: .createdAt) {
            createdAt = "\(intValue)"
        } else if let doubleValue = try? container.decodeIfPresent(Double.self, forKey: .createdAt) {
            createdAt = "\(Int64(doubleValue))"
        } else {
            createdAt = try? container.decodeIfPresent(String.self, forKey: .createdAt)
        }
    }
}

/// Type-erased Codable wrapper for heterogeneous arrays (e.g., command options).
/// Uses an enum internally so it's fully Sendable + Equatable.
public enum AnyCodable: Codable, Sendable, Equatable, CustomStringConvertible {
    case int(Int)
    case double(Double)
    case bool(Bool)
    case string(String)

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
