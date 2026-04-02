import Foundation

/// Bot configuration fetched from the API. All fields are optional with defaults for resilience.
public struct BotConfigProps: Codable, Sendable {
    public let id: String?
    public let agentId: String?
    public let theme: String?
    public let chatboxInitialMsg: String?
    public let chatboxPlaceholder: String?
    public let enableVoiceNote: Bool
    public let enableImageUpload: Bool
    public let enableRealtimeVoiceCall: Bool
    public let enableUserForm: Bool
    public let enableUserEmail: Bool
    public let enableUserPhone: Bool
    public let presetOptions: [String]?
    public let chatboxGradientColor: String?
    public let chatboxChatIcon: String?
    public let chatboxBtnIcon: String?
    public let chatboxHeaderIcon: String?
    public let chatboxSystemHeading: String?
    public let chatboxSystemParagraph: String?

    enum CodingKeys: String, CodingKey {
        case id
        case agentId = "agent_id"
        case theme
        case chatboxInitialMsg = "chatbox_initial_msg"
        case chatboxPlaceholder = "chatbox_placeholder"
        case enableVoiceNote = "enable_voice_note"
        case enableImageUpload = "enable_image_upload"
        case enableRealtimeVoiceCall = "enable_realtime_voice_call"
        case enableUserForm = "enable_user_form"
        case enableUserEmail = "enable_user_email"
        case enableUserPhone = "enable_user_phone"
        case presetOptions = "preset_options"
        case chatboxGradientColor = "chatbox_gradient_color"
        case chatboxChatIcon = "chatbox_chat_icon"
        case chatboxBtnIcon = "chatbox_btn_icon"
        case chatboxHeaderIcon = "chatbox_header_icon"
        case chatboxSystemHeading = "chatbox_system_heading"
        case chatboxSystemParagraph = "chatbox_system_paragraph"
    }

    public init(
        id: String? = nil,
        agentId: String? = nil,
        theme: String? = "light",
        chatboxInitialMsg: String? = "Hi there 👋 How can I help?",
        chatboxPlaceholder: String? = "Type your message...",
        enableVoiceNote: Bool = true,
        enableImageUpload: Bool = true,
        enableRealtimeVoiceCall: Bool = false,
        enableUserForm: Bool = true,
        enableUserEmail: Bool = true,
        enableUserPhone: Bool = false,
        presetOptions: [String]? = nil,
        chatboxGradientColor: String? = "#0047AF",
        chatboxChatIcon: String? = nil,
        chatboxBtnIcon: String? = nil,
        chatboxHeaderIcon: String? = nil,
        chatboxSystemHeading: String? = "Hi there Raya is ready to help ✨",
        chatboxSystemParagraph: String? = "Ask any question — Raya is fast and friendly."
    ) {
        self.id = id
        self.agentId = agentId
        self.theme = theme
        self.chatboxInitialMsg = chatboxInitialMsg
        self.chatboxPlaceholder = chatboxPlaceholder
        self.enableVoiceNote = enableVoiceNote
        self.enableImageUpload = enableImageUpload
        self.enableRealtimeVoiceCall = enableRealtimeVoiceCall
        self.enableUserForm = enableUserForm
        self.enableUserEmail = enableUserEmail
        self.enableUserPhone = enableUserPhone
        self.presetOptions = presetOptions
        self.chatboxGradientColor = chatboxGradientColor
        self.chatboxChatIcon = chatboxChatIcon
        self.chatboxBtnIcon = chatboxBtnIcon
        self.chatboxHeaderIcon = chatboxHeaderIcon
        self.chatboxSystemHeading = chatboxSystemHeading
        self.chatboxSystemParagraph = chatboxSystemParagraph
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        agentId = try container.decodeIfPresent(String.self, forKey: .agentId)
        theme = try container.decodeIfPresent(String.self, forKey: .theme) ?? "light"
        chatboxInitialMsg = try container.decodeIfPresent(String.self, forKey: .chatboxInitialMsg) ?? "Hi there 👋 How can I help?"
        chatboxPlaceholder = try container.decodeIfPresent(String.self, forKey: .chatboxPlaceholder) ?? "Type your message..."
        enableVoiceNote = (try? container.decodeIfPresent(Bool.self, forKey: .enableVoiceNote)) ?? true
        enableImageUpload = (try? container.decodeIfPresent(Bool.self, forKey: .enableImageUpload)) ?? true
        enableRealtimeVoiceCall = (try? container.decodeIfPresent(Bool.self, forKey: .enableRealtimeVoiceCall)) ?? false
        enableUserForm = (try? container.decodeIfPresent(Bool.self, forKey: .enableUserForm)) ?? true
        enableUserEmail = (try? container.decodeIfPresent(Bool.self, forKey: .enableUserEmail)) ?? true
        enableUserPhone = (try? container.decodeIfPresent(Bool.self, forKey: .enableUserPhone)) ?? false
        presetOptions = try container.decodeIfPresent([String].self, forKey: .presetOptions)
        chatboxGradientColor = try container.decodeIfPresent(String.self, forKey: .chatboxGradientColor) ?? "#0047AF"
        chatboxChatIcon = try container.decodeIfPresent(String.self, forKey: .chatboxChatIcon)
        chatboxBtnIcon = try container.decodeIfPresent(String.self, forKey: .chatboxBtnIcon)
        chatboxHeaderIcon = try container.decodeIfPresent(String.self, forKey: .chatboxHeaderIcon)
        chatboxSystemHeading = try container.decodeIfPresent(String.self, forKey: .chatboxSystemHeading) ?? "Hi there Raya is ready to help ✨"
        chatboxSystemParagraph = try container.decodeIfPresent(String.self, forKey: .chatboxSystemParagraph) ?? "Ask any question — Raya is fast and friendly."
    }
}
