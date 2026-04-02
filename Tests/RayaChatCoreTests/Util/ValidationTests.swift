import XCTest
@testable import RayaChatCore

final class ValidationTests: XCTestCase {

    // MARK: - Email

    func testValidEmails() {
        XCTAssertTrue(validateEmail("user@example.com"))
        XCTAssertTrue(validateEmail("first.last@company.co.uk"))
        XCTAssertTrue(validateEmail("test+tag@gmail.com"))
    }

    func testInvalidEmails() {
        XCTAssertFalse(validateEmail(""))
        XCTAssertFalse(validateEmail("notanemail"))
        XCTAssertFalse(validateEmail("@missing.com"))
        XCTAssertFalse(validateEmail("user@"))
        XCTAssertFalse(validateEmail("user@.com"))
    }

    // MARK: - Phone

    func testValidPhones() {
        XCTAssertTrue(validatePhone("+1234567890"))
        XCTAssertTrue(validatePhone("123-456-7890"))
        XCTAssertTrue(validatePhone("(123) 456-7890"))
        XCTAssertTrue(validatePhone("+44 20 7946 0958"))
    }

    func testInvalidPhones() {
        XCTAssertFalse(validatePhone(""))
        XCTAssertFalse(validatePhone("123"))
        XCTAssertFalse(validatePhone("abcdefghij"))
    }
}
