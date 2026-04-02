import XCTest
@testable import RayaChatCore

final class TimeFormatTests: XCTestCase {

    func testFormatsEpochSeconds() {
        // Use a known timestamp and check format pattern
        let result = formatLocalTime(epochSeconds: 1700000000)
        XCTAssertNotNil(result)
        // Should contain AM or PM
        XCTAssertTrue(result!.contains("AM") || result!.contains("PM"),
                       "Expected AM/PM format, got: \(result!)")
    }

    func testNilReturnsNil() {
        XCTAssertNil(formatLocalTime(epochSeconds: nil))
    }

    func testZeroReturnsNil() {
        XCTAssertNil(formatLocalTime(epochSeconds: 0))
    }

    func testNegativeReturnsNil() {
        XCTAssertNil(formatLocalTime(epochSeconds: -1))
    }

    func testFormatOrEmptyReturnsString() {
        XCTAssertFalse(formatLocalTimeOrEmpty(epochSeconds: 1700000000).isEmpty)
    }

    func testFormatOrEmptyReturnsEmptyForNil() {
        XCTAssertEqual(formatLocalTimeOrEmpty(epochSeconds: nil), "")
    }
}
