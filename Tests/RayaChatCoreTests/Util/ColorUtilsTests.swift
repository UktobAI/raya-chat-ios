import XCTest
@testable import RayaChatCore

final class ColorUtilsTests: XCTestCase {

    func testDarkBlueIsDark() {
        XCTAssertTrue(isDarkColor("#0047AF"))
    }

    func testBlackIsDark() {
        XCTAssertTrue(isDarkColor("#000000"))
    }

    func testWhiteIsNotDark() {
        XCTAssertFalse(isDarkColor("#FFFFFF"))
    }

    func testYellowIsNotDark() {
        XCTAssertFalse(isDarkColor("#FFFF00"))
    }

    func testMidGrayIsDark() {
        // luminance ~ 0.46 < 0.5
        XCTAssertTrue(isDarkColor("#707070"))
    }

    func testLightGrayIsNotDark() {
        XCTAssertFalse(isDarkColor("#CCCCCC"))
    }

    func testShortHexWorks() {
        XCTAssertFalse(isDarkColor("#FFF"))
        XCTAssertTrue(isDarkColor("#000"))
    }

    func testNoHashPrefix() {
        XCTAssertTrue(isDarkColor("0047AF"))
    }

    func testInvalidHexReturnsDark() {
        XCTAssertTrue(isDarkColor("notacolor"))
    }

    func testContrastColorDark() {
        XCTAssertEqual(getContrastColor("#000000"), "#FFFFFF")
    }

    func testContrastColorLight() {
        XCTAssertEqual(getContrastColor("#FFFFFF"), "#1A1A1A")
    }

    func testParseHexColorSixDigit() {
        XCTAssertEqual(parseHexColor("#FF5733"), 0xFF5733)
    }

    func testParseHexColorThreeDigit() {
        // #F00 → #FF0000
        XCTAssertEqual(parseHexColor("#F00"), 0xFF0000)
    }

    func testParseHexColorInvalid() {
        XCTAssertNil(parseHexColor("xyz"))
        XCTAssertNil(parseHexColor("#12345")) // 5 digits
    }
}
