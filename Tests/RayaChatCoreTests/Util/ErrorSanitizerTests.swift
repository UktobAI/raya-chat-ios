import XCTest
@testable import RayaChatCore

final class ErrorSanitizerTests: XCTestCase {

    func testNilInputReturnsDefault() {
        XCTAssertEqual(
            sanitizeErrorMessage(nil),
            "An unexpected error occurred. Please try again."
        )
    }

    func testEmptyInputReturnsDefault() {
        XCTAssertEqual(
            sanitizeErrorMessage(""),
            "An unexpected error occurred. Please try again."
        )
    }

    func testNormalMessagePassesThrough() {
        XCTAssertEqual(sanitizeErrorMessage("Connection failed"), "Connection failed")
    }

    func testStripsHTMLTags() {
        let result = sanitizeErrorMessage("<script>alert('xss')</script>Error occurred")
        XCTAssertFalse(result.contains("<script>"))
        XCTAssertTrue(result.contains("Error occurred"))
    }

    func testStripsJavascriptProtocol() {
        let result = sanitizeErrorMessage("javascript:alert(1)")
        XCTAssertFalse(result.lowercased().contains("javascript:"))
    }

    func testStripsEventHandlers() {
        let result = sanitizeErrorMessage("onclick=alert(1) Error")
        XCTAssertFalse(result.contains("onclick="))
    }

    func testRedactsSensitivePatterns() {
        XCTAssertEqual(
            sanitizeErrorMessage("Invalid api_key: abc123"),
            "An unexpected error occurred. Please try again."
        )
        XCTAssertEqual(
            sanitizeErrorMessage("Wrong password provided"),
            "An unexpected error occurred. Please try again."
        )
        XCTAssertEqual(
            sanitizeErrorMessage("Bearer token expired"),
            "An unexpected error occurred. Please try again."
        )
    }

    func testTruncatesLongMessages() {
        let longMessage = String(repeating: "a", count: 300)
        let result = sanitizeErrorMessage(longMessage)
        XCTAssertTrue(result.count <= 203) // 200 + "..."
    }

    func testWhitespaceOnlyReturnsDefault() {
        XCTAssertEqual(
            sanitizeErrorMessage("   "),
            "An unexpected error occurred. Please try again."
        )
    }
}
