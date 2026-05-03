import XCTest
@testable import RayaChatCore

final class APIClientTests: XCTestCase {

    func testConstructWebSocketUrlContainsRequiredParams() {
        let client = APIClient(token: "test-token", locale: "en")
        let userInfo = UserInfo(fullName: "John Doe", email: "john@test.com", phone: "+1234567890")

        let url = client.constructWebSocketUrl(sessionId: "session-123", userInfo: userInfo)

        XCTAssertTrue(url.hasPrefix("wss://"))
        XCTAssertTrue(url.contains("integration_type=widget"))
        XCTAssertTrue(url.contains("token=test-token"))
        XCTAssertTrue(url.contains("chat_session_id=session-123"))
        XCTAssertTrue(url.contains("agent_id=null"))
    }

    func testConstructWebSocketUrlEncodesUserInfo() {
        let client = APIClient(token: "test-token", locale: "en")
        let userInfo = UserInfo(fullName: "John Doe", email: "john@test.com", phone: "+1234567890")

        let url = client.constructWebSocketUrl(sessionId: "", userInfo: userInfo)

        // URLComponents should encode spaces and special characters
        XCTAssertTrue(url.contains("user_name=John"))
        XCTAssertTrue(url.contains("email=john"))
    }

    func testConstructWebSocketUrlEmptySessionId() {
        let client = APIClient(token: "test-token", locale: "en")
        let userInfo = UserInfo()

        let url = client.constructWebSocketUrl(sessionId: "", userInfo: userInfo)

        XCTAssertTrue(url.contains("chat_session_id="))
    }

    func testConstructWebSocketUrlContainsDataParam() {
        let client = APIClient(token: "test-token", locale: "ar")
        let userInfo = UserInfo()

        let url = client.constructWebSocketUrl(sessionId: "", userInfo: userInfo)

        // data param should contain URL-encoded JSON with platform info
        XCTAssertTrue(url.contains("data="))
    }

    func testConstructWebSocketUrlUsesCorrectEndpoint() {
        let client = APIClient(token: "test-token")
        let url = client.constructWebSocketUrl(sessionId: "", userInfo: UserInfo())

        XCTAssertTrue(url.contains(Constants.defaultEndpoint))
        XCTAssertTrue(url.contains("/v1/enhanced-chat/ws/stream"))
    }
}
