import XCTest
@testable import RayaChatCore

final class TextDirectionTests: XCTestCase {

    // MARK: - isRTLLocale

    func testArabicIsRTL() {
        XCTAssertTrue(isRTLLocale("ar"))
        XCTAssertTrue(isRTLLocale("ar-SA"))
        XCTAssertTrue(isRTLLocale("AR"))
    }

    func testHebrewIsRTL() {
        XCTAssertTrue(isRTLLocale("he"))
        XCTAssertTrue(isRTLLocale("he-IL"))
    }

    func testFarsiIsRTL() {
        XCTAssertTrue(isRTLLocale("fa"))
    }

    func testUrduIsRTL() {
        XCTAssertTrue(isRTLLocale("ur"))
    }

    func testEnglishIsNotRTL() {
        XCTAssertFalse(isRTLLocale("en"))
        XCTAssertFalse(isRTLLocale("en-US"))
    }

    func testFrenchIsNotRTL() {
        XCTAssertFalse(isRTLLocale("fr"))
    }

    // MARK: - isRTLText

    func testArabicTextIsRTL() {
        XCTAssertTrue(isRTLText("مرحبا"))
    }

    func testHebrewTextIsRTL() {
        XCTAssertTrue(isRTLText("שלום"))
    }

    func testEnglishTextIsNotRTL() {
        XCTAssertFalse(isRTLText("Hello World"))
    }

    func testMixedTextDetectsRTL() {
        XCTAssertTrue(isRTLText("Hello مرحبا World"))
    }

    func testEmptyTextIsNotRTL() {
        XCTAssertFalse(isRTLText(""))
    }

    func testNumbersAreNotRTL() {
        XCTAssertFalse(isRTLText("12345"))
    }

    func testEmojiIsNotRTL() {
        XCTAssertFalse(isRTLText("👋🎉"))
    }
}
