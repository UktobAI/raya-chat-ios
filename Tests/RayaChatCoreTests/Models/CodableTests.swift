import XCTest
@testable import RayaChatCore

final class CodableTests: XCTestCase {

    private let decoder = JSONDecoder()
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = .sortedKeys
        return e
    }()

    // MARK: - BotConfigProps

    func testBotConfigDeserializesFromServerJSON() throws {
        let json = """
        {
            "id": "bot-1",
            "agent_id": "agent-1",
            "theme": "dark",
            "chatbox_initial_msg": "Hello!",
            "chatbox_placeholder": "Ask me...",
            "enable_voice_note": false,
            "enable_image_upload": true,
            "enable_realtime_voice_call": false,
            "enable_user_form": true,
            "enable_user_email": true,
            "enable_user_phone": false,
            "preset_options": ["Option A", "Option B"],
            "chatbox_gradient_color": "#FF5733",
            "chatbox_chat_icon": "https://example.com/icon.png",
            "chatbox_system_heading": "Welcome!",
            "chatbox_system_paragraph": "How can I help?"
        }
        """.data(using: .utf8)!

        let config = try decoder.decode(BotConfigProps.self, from: json)

        XCTAssertEqual(config.id, "bot-1")
        XCTAssertEqual(config.agentId, "agent-1")
        XCTAssertEqual(config.theme, "dark")
        XCTAssertEqual(config.chatboxInitialMsg, "Hello!")
        XCTAssertEqual(config.chatboxPlaceholder, "Ask me...")
        XCTAssertEqual(config.enableVoiceNote, false)
        XCTAssertEqual(config.enableImageUpload, true)
        XCTAssertEqual(config.presetOptions, ["Option A", "Option B"])
        XCTAssertEqual(config.chatboxGradientColor, "#FF5733")
        XCTAssertEqual(config.chatboxChatIcon, "https://example.com/icon.png")
        XCTAssertEqual(config.chatboxSystemHeading, "Welcome!")
    }

    func testBotConfigHandlesNullFields() throws {
        let json = """
        {
            "id": null,
            "theme": null,
            "chatbox_chat_icon": null,
            "chatbox_gradient_color": null,
            "chatbox_system_heading": null,
            "enable_voice_note": true
        }
        """.data(using: .utf8)!

        let config = try decoder.decode(BotConfigProps.self, from: json)

        XCTAssertNil(config.id)
        XCTAssertEqual(config.theme, "light") // default
        XCTAssertNil(config.chatboxChatIcon)
        XCTAssertEqual(config.chatboxGradientColor, "#0047AF") // default
        XCTAssertEqual(config.chatboxSystemHeading, "Hi there Raya is ready to help ✨") // default
    }

    func testBotConfigHandlesEmptyJSON() throws {
        let json = "{}".data(using: .utf8)!
        let config = try decoder.decode(BotConfigProps.self, from: json)

        XCTAssertEqual(config.theme, "light")
        XCTAssertEqual(config.enableVoiceNote, true)
        XCTAssertEqual(config.enableUserForm, true)
        XCTAssertEqual(config.chatboxGradientColor, "#0047AF")
    }

    func testBotConfigDefaultInit() {
        let config = BotConfigProps()
        XCTAssertEqual(config.theme, "light")
        XCTAssertEqual(config.enableImageUpload, true)
        XCTAssertEqual(config.chatboxGradientColor, "#0047AF")
    }

    // MARK: - Attachment

    func testAttachmentRoundTrip() throws {
        let att = Attachment(id: "att-1", url: "https://img.com/1.png", type: "image", name: "photo.png")
        let data = try encoder.encode(att)
        let decoded = try decoder.decode(Attachment.self, from: data)

        XCTAssertEqual(decoded.id, "att-1")
        XCTAssertEqual(decoded.url, "https://img.com/1.png")
        XCTAssertEqual(decoded.type, "image")
        XCTAssertEqual(decoded.name, "photo.png")
    }

    func testAttachmentDefaults() {
        let att = Attachment()
        XCTAssertEqual(att.id, "")
        XCTAssertEqual(att.type, "image")
    }

    // MARK: - AudioData

    func testAudioDataRoundTrip() throws {
        let audio = AudioData(type: "remote", audioUrls: "https://audio.com/1.mp3")
        let data = try encoder.encode(audio)
        let decoded = try decoder.decode(AudioData.self, from: data)

        XCTAssertEqual(decoded.type, "remote")
        XCTAssertEqual(decoded.audioUrls, "https://audio.com/1.mp3")
    }

    func testAudioDataSnakeCaseDecoding() throws {
        let json = """
        {"type": "local", "audio_urls": "data:audio/mp3;base64,abc"}
        """.data(using: .utf8)!

        let decoded = try decoder.decode(AudioData.self, from: json)
        XCTAssertEqual(decoded.type, "local")
        XCTAssertEqual(decoded.audioUrls, "data:audio/mp3;base64,abc")
    }

    // MARK: - UserInfo

    func testUserInfoRoundTrip() throws {
        let user = UserInfo(fullName: "John Doe", email: "john@test.com", phone: "+1234567890")
        let data = try encoder.encode(user)
        let decoded = try decoder.decode(UserInfo.self, from: data)

        XCTAssertEqual(decoded.fullName, "John Doe")
        XCTAssertEqual(decoded.email, "john@test.com")
        XCTAssertEqual(decoded.phone, "+1234567890")
    }

    // MARK: - DeviceMetadata

    func testDeviceMetadataEncoding() throws {
        let meta = DeviceMetadata(
            platform: "ios",
            osVersion: "17.0",
            deviceFamily: "iOS",
            sdkVersion: "0.1.0",
            locale: "en",
            timezone: "Asia/Dubai"
        )
        let data = try encoder.encode(meta)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("\"platform\":\"ios\""))
        XCTAssertTrue(jsonString.contains("\"os_version\":\"17.0\""))
        XCTAssertTrue(jsonString.contains("\"device_family\":\"iOS\""))
        XCTAssertTrue(jsonString.contains("\"sdk_version\":\"0.1.0\""))
    }

    // MARK: - ChatMessage

    func testChatMessageDecodesResponseType() throws {
        // created_at is a number (Long) from server — matches actual production response
        let json = """
        {
            "type": "response",
            "data": {
                "id": "msg-1",
                "chat_session_id": "session-1",
                "sender": 2,
                "content": "Hello from bot",
                "created_at": 1700000000
            }
        }
        """.data(using: .utf8)!

        let msg = try decoder.decode(ChatMessage.self, from: json)
        XCTAssertEqual(msg.type, "response")
        XCTAssertEqual(msg.data?.id, "msg-1")
        XCTAssertEqual(msg.data?.chatSessionId, "session-1")
        XCTAssertEqual(msg.data?.sender, 2)
        XCTAssertEqual(msg.data?.content, "Hello from bot")
        XCTAssertEqual(msg.data?.createdAt, "1700000000") // number → string conversion
    }

    func testChatResponseDataHandlesStringCreatedAt() throws {
        let json = """
        {"id": "msg-2", "chat_session_id": "s-1", "sender": 2, "content": "Hi", "created_at": "1700000000"}
        """.data(using: .utf8)!

        let data = try decoder.decode(ChatResponseData.self, from: json)
        XCTAssertEqual(data.createdAt, "1700000000")
    }

    func testChatMessageDecodesPresetsType() throws {
        // Presets from server are objects with id, title, prompt — not plain strings
        let json = """
        {"type": "presets", "presets": [{"id":"1","title":"Option A","prompt":"prompt A"},{"id":"2","title":"Option B","prompt":"prompt B"}]}
        """.data(using: .utf8)!

        let msg = try decoder.decode(ChatMessage.self, from: json)
        XCTAssertEqual(msg.type, "presets")
        XCTAssertEqual(msg.presets?.count, 2)
        XCTAssertEqual(msg.presets?.first?.title, "Option A")
        XCTAssertEqual(msg.presets?.first?.prompt, "prompt A")
    }

    func testChatMessageDecodesCommandType() throws {
        let json = """
        {
            "type": "command",
            "command": "rate_conversation",
            "content": "rate_conversation",
            "options": [1, 2, 3, 4, 5],
            "message": "How was your experience?"
        }
        """.data(using: .utf8)!

        let msg = try decoder.decode(ChatMessage.self, from: json)
        XCTAssertEqual(msg.type, "command")
        XCTAssertEqual(msg.command, "rate_conversation")
        XCTAssertEqual(msg.content, "rate_conversation")
        XCTAssertEqual(msg.message, "How was your experience?")
        XCTAssertEqual(msg.options?.count, 5)
    }

    // MARK: - OutboundMessage

    func testOutboundMessageEncoding() throws {
        let msg = OutboundMessage(
            content: "Hello",
            images: [OutboundImage(name: "photo.jpg", type: "image/jpeg", data: "base64data")]
        )
        let data = try encoder.encode(msg)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("\"content\":\"Hello\""))
        XCTAssertTrue(jsonString.contains("\"name\":\"photo.jpg\""))
        XCTAssertTrue(jsonString.contains("\"data\":\"base64data\""))
    }

    func testOutboundCommandResponseEncoding() throws {
        let cmd = OutboundCommandResponse(command: "rate_conversation", response: "5")
        let data = try encoder.encode(cmd)
        let jsonString = String(data: data, encoding: .utf8)!

        XCTAssertTrue(jsonString.contains("\"command\":\"rate_conversation\""))
        XCTAssertTrue(jsonString.contains("\"response\":\"5\""))
        XCTAssertTrue(jsonString.contains("\"type\":\"command_response\""))
    }

    // MARK: - TypeMessage

    func testTypeMessageAttachmentsParsing() {
        let attachmentsJson = """
        [{"id":"a1","url":"https://img.com/1.png","type":"image","name":"photo.png"}]
        """
        let msg = TypeMessage(id: "m1", sender: 1, type: 3, attachmentsJson: attachmentsJson)

        XCTAssertEqual(msg.attachments.count, 1)
        XCTAssertEqual(msg.attachments.first?.url, "https://img.com/1.png")
    }

    func testTypeMessageAudioParsing() {
        let audioJson = """
        {"type":"remote","audio_urls":"https://audio.com/1.mp3"}
        """
        let msg = TypeMessage(id: "m2", sender: 2, type: 2, audioJson: audioJson)

        XCTAssertNotNil(msg.audio)
        XCTAssertEqual(msg.audio?.type, "remote")
        XCTAssertEqual(msg.audio?.audioUrls, "https://audio.com/1.mp3")
    }

    func testTypeMessageNilAttachments() {
        let msg = TypeMessage(id: "m3", sender: 1, type: 1, content: "Hello")
        XCTAssertEqual(msg.attachments, [])
        XCTAssertNil(msg.audio)
    }

    // MARK: - AnyCodable

    func testAnyCodableDecodesInt() throws {
        let json = "42".data(using: .utf8)!
        let decoded = try decoder.decode(AnyCodable.self, from: json)
        XCTAssertEqual(decoded, .int(42))
        XCTAssertEqual(decoded.value as? Int, 42)
    }

    func testAnyCodableDecodesString() throws {
        let json = "\"hello\"".data(using: .utf8)!
        let decoded = try decoder.decode(AnyCodable.self, from: json)
        XCTAssertEqual(decoded, .string("hello"))
        XCTAssertEqual(decoded.value as? String, "hello")
    }

    func testAnyCodableDecodesBool() throws {
        let json = "true".data(using: .utf8)!
        let decoded = try decoder.decode(AnyCodable.self, from: json)
        XCTAssertEqual(decoded, .bool(true))
        XCTAssertEqual(decoded.value as? Bool, true)
    }

    func testAnyCodableDescription() {
        XCTAssertEqual(AnyCodable.int(42).description, "42")
        XCTAssertEqual(AnyCodable.string("hello").description, "hello")
        XCTAssertEqual(AnyCodable.bool(true).description, "true")
    }
}
