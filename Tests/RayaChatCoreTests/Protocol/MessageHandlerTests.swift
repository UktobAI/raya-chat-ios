import XCTest
@testable import RayaChatCore

final class MessageHandlerTests: XCTestCase {

    private var handler: MessageHandler!
    private var delegate: MockDelegate!

    override func setUp() {
        super.setUp()
        handler = MessageHandler()
        delegate = MockDelegate()
        handler.delegate = delegate
    }

    // MARK: - STEP

    func testHandleStep() {
        handler.handle("""
        {"type":"step","text":"Searching..."}
        """)
        XCTAssertTrue(delegate.stepCalled)
        XCTAssertEqual(delegate.lastStepText, "Searching...")
    }

    func testHandleStepNilText() {
        handler.handle("""
        {"type":"step"}
        """)
        XCTAssertTrue(delegate.stepCalled)
        XCTAssertNil(delegate.lastStepText)
    }

    // MARK: - CHUNK

    func testHandleChunk() {
        handler.handle("""
        {"type":"chunk","text":"Hello "}
        """)
        XCTAssertEqual(delegate.lastChunkText, "Hello ")
    }

    func testHandleChunkFromContent() {
        handler.handle("""
        {"type":"chunk","content":"world"}
        """)
        XCTAssertEqual(delegate.lastChunkText, "world")
    }

    func testHandleChunkEmpty() {
        handler.handle("""
        {"type":"chunk","text":""}
        """)
        XCTAssertNil(delegate.lastChunkText) // Empty chunks ignored
    }

    // MARK: - RESPONSE

    func testHandleResponse() {
        handler.handle("""
        {"type":"response","data":{"id":"msg-1","chat_session_id":"session-abc","sender":2,"content":"Hello from bot","created_at":"1700000000"}}
        """)
        XCTAssertNotNil(delegate.lastResponse)
        XCTAssertEqual(delegate.lastResponse?.id, "msg-1")
        XCTAssertEqual(delegate.lastResponse?.content, "Hello from bot")
        XCTAssertEqual(delegate.lastSessionId, "session-abc")
    }

    func testHandleResponseUpdatesSessionId() {
        handler.handle("""
        {"type":"response","data":{"id":"msg-1","chat_session_id":"new-session-id","sender":2,"content":"Hi"}}
        """)
        XCTAssertEqual(delegate.lastSessionUpdateId, "new-session-id")
    }

    // MARK: - PRESETS

    func testHandlePresets() {
        handler.handle("""
        {"type":"presets","presets":["Option A","Option B","Option C"]}
        """)
        XCTAssertEqual(delegate.lastPresets, ["Option A", "Option B", "Option C"])
    }

    func testHandlePresetsEmpty() {
        handler.handle("""
        {"type":"presets","presets":[]}
        """)
        XCTAssertEqual(delegate.lastPresets, [])
    }

    // MARK: - COMMAND

    func testHandleRateConversation() {
        handler.handle("""
        {"type":"command","content":"rate_conversation","options":[1,2,3,4,5],"message":"How was your experience?"}
        """)
        XCTAssertNotNil(delegate.lastCommand)
        XCTAssertEqual(delegate.lastCommand?.content, "rate_conversation")
        XCTAssertEqual(delegate.lastCommand?.message, "How was your experience?")
        XCTAssertEqual(delegate.lastCommand?.options.count, 5)
    }

    func testHandleEndSession() {
        handler.handle("""
        {"type":"command","content":"end_session","options":["Yes","No"],"message":"End this chat?"}
        """)
        XCTAssertNotNil(delegate.lastCommand)
        XCTAssertEqual(delegate.lastCommand?.content, "end_session")
    }

    func testHandleSubmitFeedback() {
        handler.handle("""
        {"type":"command","content":"submit_feedback","message":"Please share feedback","optional":true}
        """)
        XCTAssertNotNil(delegate.lastCommand)
        XCTAssertEqual(delegate.lastCommand?.content, "submit_feedback")
        XCTAssertEqual(delegate.lastCommand?.optional, true)
    }

    func testHandleFeedbackReceived() {
        handler.handle("""
        {"type":"command","content":"feedback_received","message":"Thank you!"}
        """)
        XCTAssertNotNil(delegate.lastCommand)
        XCTAssertEqual(delegate.lastCommand?.content, "feedback_received")
    }

    func testHandleAutoClose() {
        handler.handle("""
        {"type":"command","content":"auto_close","message":"Session closed due to inactivity."}
        """)
        // auto_close triggers onError, not onCommand
        XCTAssertNil(delegate.lastCommand)
        XCTAssertNotNil(delegate.lastErrorText)
    }

    func testHandleInvalidCommand() {
        handler.handle("""
        {"type":"command","content":"unknown_command"}
        """)
        XCTAssertNil(delegate.lastCommand) // Invalid commands ignored
    }

    // MARK: - ERROR

    func testHandleError() {
        handler.handle("""
        {"type":"error","text":"Something went wrong"}
        """)
        XCTAssertEqual(delegate.lastErrorText, "Something went wrong")
    }

    // MARK: - ESCALATION

    func testHandleEscalation() {
        handler.handle("""
        {"type":"escalation"}
        """)
        XCTAssertTrue(delegate.escalationCalled)
    }

    // MARK: - INFO

    func testHandleInfo() {
        handler.handle("""
        {"type":"info","text":"Waiting for human agent..."}
        """)
        XCTAssertEqual(delegate.lastInfoText, "Waiting for human agent...")
    }

    // MARK: - AGENT_ACTIVITY

    func testHandleAgentActivity() {
        handler.handle("""
        {"type":"agent_activity","text":"Agent John joined"}
        """)
        XCTAssertNotNil(delegate.lastAgentActivity)
        XCTAssertEqual(delegate.lastAgentActivity?.content, "Agent John joined")
        XCTAssertEqual(delegate.lastAgentActivity?.type, 4)
    }

    // MARK: - MESSAGE

    func testHandleMessage() {
        handler.handle("""
        {"type":"message","text":"Generic server message"}
        """)
        XCTAssertNotNil(delegate.lastServerMessage)
        XCTAssertEqual(delegate.lastServerMessage?.content, "Generic server message")
    }

    // MARK: - Edge cases

    func testHandleInvalidJSON() {
        handler.handle("not json at all")
        // Should not crash, delegate methods not called
        XCTAssertFalse(delegate.stepCalled)
    }

    func testHandleUnknownType() {
        handler.handle("""
        {"type":"future_type_v2","text":"something"}
        """)
        // Should not crash
        XCTAssertFalse(delegate.stepCalled)
    }

    func testHandleMissingType() {
        handler.handle("""
        {"text":"no type field"}
        """)
        XCTAssertFalse(delegate.stepCalled)
    }
}

// MARK: - Mock Delegate

private class MockDelegate: MessageHandlerDelegate {
    var stepCalled = false
    var lastStepText: String?
    var lastChunkText: String?
    var lastResponse: TypeMessage?
    var lastSessionId: String?
    var lastSessionUpdateId: String?
    var lastPresets: [String]?
    var lastCommand: CommandData?
    var lastErrorText: String?
    var escalationCalled = false
    var lastInfoText: String?
    var lastAgentActivity: TypeMessage?
    var lastServerMessage: TypeMessage?

    func onStep(text: String?) {
        stepCalled = true
        lastStepText = text
    }

    func onChunk(text: String) {
        lastChunkText = text
    }

    func onResponse(message: TypeMessage, sessionId: String?) {
        lastResponse = message
        lastSessionId = sessionId
    }

    func onPresets(_ presets: [String]) {
        lastPresets = presets
    }

    func onCommand(data: CommandData) {
        lastCommand = data
    }

    func onError(text: String) {
        lastErrorText = text
    }

    func onEscalation(showButton: Bool) {
        escalationCalled = true
    }

    func onInfo(text: String?) {
        lastInfoText = text
    }

    func onAgentActivity(message: TypeMessage) {
        lastAgentActivity = message
    }

    func onServerMessage(message: TypeMessage) {
        lastServerMessage = message
    }

    func onSessionUpdate(sessionId: String) {
        lastSessionUpdateId = sessionId
    }

    func onAttachments(attachments: [String], type: String) {}
}
