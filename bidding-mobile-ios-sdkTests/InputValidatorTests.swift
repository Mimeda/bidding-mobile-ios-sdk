import XCTest
@testable import bidding_mobile_ios_sdk

final class InputValidatorTests: XCTestCase {

    func testSanitizeString_RemovesScriptTags() {
        // Given
        let input = "test<script>alert('xss')</script>value"

        // When
        let result = InputValidator.sanitizeString(input)

        // Then
        XCTAssertEqual(result, "testvalue")
    }

    func testSanitizeString_RemovesHtmlTags() {
        // Given
        let input = "test<b>bold</b>value"

        // When
        let result = InputValidator.sanitizeString(input)

        // Then
        XCTAssertEqual(result, "testboldvalue")
    }

    func testSanitizeString_RemovesNullBytes() {
        // Given
        let input = "test\u{0000}value"

        // When
        let result = InputValidator.sanitizeString(input)

        // Then
        XCTAssertEqual(result, "testvalue")
    }

    func testSanitizeString_RemovesSqlInjection() {
        // Given
        let input = "test'; DROP TABLE users; --"

        // When
        let result = InputValidator.sanitizeString(input)

        // Then
        XCTAssertNotEqual(result, input)
        XCTAssertFalse(result?.contains("DROP") ?? false)
    }

    func testSanitizeString_TruncatesLongString() {
        // Given
        let longString = String(repeating: "a", count: 2000)

        // When
        let result = InputValidator.sanitizeString(longString, maxLength: 1024)

        // Then
        XCTAssertEqual(result?.count, 1024)
    }

    func testSanitizeString_TrimsWhitespace() {
        // Given
        let input = "  test value  "

        // When
        let result = InputValidator.sanitizeString(input)

        // Then
        XCTAssertEqual(result, "test value")
    }

    func testSanitizeString_NilOrEmpty_ReturnsAsIs() {
        // Given & When & Then
        XCTAssertNil(InputValidator.sanitizeString(nil))
        XCTAssertEqual(InputValidator.sanitizeString(""), "")
        XCTAssertEqual(InputValidator.sanitizeString("   "), "")
    }

    func testSanitizeUserId_AppliesMaxLength() {
        // Given
        let longUserId = String(repeating: "a", count: 300)

        // When
        let result = InputValidator.sanitizeUserId(longUserId)

        // Then
        XCTAssertEqual(result?.count, 256)
    }

    func testSanitizeKeyword_AppliesMaxLength() {
        // Given
        let longKeyword = String(repeating: "a", count: 300)

        // When
        let result = InputValidator.sanitizeKeyword(longKeyword)

        // Then
        XCTAssertEqual(result?.count, 256)
    }

    func testSanitizePayload_AppliesMaxLength() {
        // Given
        let longPayload = String(repeating: "a", count: 70000)

        // When
        let result = InputValidator.sanitizePayload(longPayload)

        // Then
        XCTAssertEqual(result?.count, 65536)
    }

    func testSanitizeProductList_KeepsDelimitersAndDoesNotTruncate() {
        // Given
        let input = "SKU1:1:10.0;SKU2:2:20.0"

        // When
        let result = InputValidator.sanitizeProductList(input)

        // Then
        XCTAssertEqual(result, input)
    }

    func testSanitizeProductList_RemovesHtmlAndScriptAndNullChar() {
        // Given
        let input = "  SKU1:1:10.0;\u{0000}<script>alert(1)</script><b>SKU2</b>:2:20.0  "

        // When
        let result = InputValidator.sanitizeProductList(input)

        // Then
        XCTAssertEqual(result, "SKU1:1:10.0;SKU2:2:20.0")
    }

    func testSanitizeProductList_NilOrBlank_Passthrough() {
        // Given & When & Then
        XCTAssertNil(InputValidator.sanitizeProductList(nil))
        XCTAssertEqual(InputValidator.sanitizeProductList(""), "")
        XCTAssertEqual(InputValidator.sanitizeProductList("   "), "")
    }

    func testContainsSqlInjection_DetectsSqlInjection() {
        // Given
        let input = "test'; DROP TABLE users; --"

        // When
        let result = InputValidator.containsSqlInjection(input)

        // Then
        XCTAssertTrue(result)
    }

    func testContainsSqlInjection_NoInjection_ReturnsFalse() {
        // Given
        let input = "normal text"

        // When
        let result = InputValidator.containsSqlInjection(input)

        // Then
        XCTAssertFalse(result)
    }

    func testContainsSqlInjection_NilOrEmpty_ReturnsFalse() {
        // Given & When & Then
        XCTAssertFalse(InputValidator.containsSqlInjection(nil))
        XCTAssertFalse(InputValidator.containsSqlInjection(""))
        XCTAssertFalse(InputValidator.containsSqlInjection("   "))
    }
}

