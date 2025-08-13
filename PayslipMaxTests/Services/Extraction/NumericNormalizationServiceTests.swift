import XCTest
@testable import PayslipMax

final class NumericNormalizationServiceTests: XCTestCase {
    var normalizer: NumericNormalizationServiceProtocol!

    override func setUp() {
        super.setUp()
        normalizer = NumericNormalizationService()
    }

    func testSimpleAmount() {
        let v = normalizer.normalizeAmount("12,345.67")
        XCTAssertNotNil(v)
        XCTAssertEqual(v!, 12345.67, accuracy: 0.0001)
    }

    func testCurrencySymbolsAndSpaces() {
        let a = normalizer.normalizeAmount("Rs. 1,00,000")
        XCTAssertNotNil(a)
        XCTAssertEqual(a!, 100000, accuracy: 0.0001)
        let b = normalizer.normalizeAmount("₹ 25,500")
        XCTAssertNotNil(b)
        XCTAssertEqual(b!, 25500, accuracy: 0.0001)
    }

    func testParenthesesNegative() {
        let v = normalizer.normalizeAmount("(1,234.50)")
        XCTAssertNotNil(v)
        XCTAssertEqual(v!, -1234.50, accuracy: 0.0001)
    }

    func testOCRConfusions() {
        // O->0, I->1, S->5
        let v = normalizer.normalizeAmount("1O,OOI.S")
        XCTAssertNotNil(v)
        XCTAssertEqual(v!, 10001.5, accuracy: 0.0001)
    }

    func testDevanagariNumerals() {
        let v = normalizer.normalizeAmount("₹ १२,३४५.६७")
        XCTAssertNotNil(v)
        XCTAssertEqual(v!, 12345.67, accuracy: 0.0001)
    }

    func testHindiMinusAndSpacesVariants() {
        // Use Unicode minus and non-breaking spaces
        let minus = "\u{2212}"
        let nbsp = "\u{00A0}"
        let v = normalizer.normalizeAmount("₹\(nbsp)1,234.50\(nbsp)\(minus)")
        // Trailing minus is unusual; normalization removes extraneous minus and currency, still parses
        XCTAssertNotNil(v)
        XCTAssertEqual(v!, 1234.50, accuracy: 0.0001)
    }

    func testRejectAlphaHeavy() {
        XCTAssertNil(normalizer.normalizeAmount("ABC"))
    }
}


