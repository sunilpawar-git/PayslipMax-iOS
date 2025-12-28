//
//  LLMResponsePIIScubberTests.swift
//  PayslipMaxTests
//
//  Tests for PII scrubber functionality
//  Additional tests in: LLMResponsePIIScubberTests+PIITests.swift
//

import XCTest
@testable import PayslipMax

final class LLMResponsePIIScubberTests: XCTestCase {
    var scrubber: LLMResponsePIIScrubber!

    override func setUp() {
        super.setUp()
        scrubber = LLMResponsePIIScrubber()
    }

    override func tearDown() {
        scrubber = nil
        super.tearDown()
    }

    // MARK: - PAN Detection Tests

    func testDetectsPANInResponse() {
        let response = """
        {
          "earnings": {"BPAY": 37000},
          "pan": "ABCDE1234F"
        }
        """

        let result = scrubber.scrub(response)

        XCTAssertFalse(result.isClean, "Should detect PAN")
        XCTAssertEqual(result.detectedPII.count, 1)
        XCTAssertEqual(result.detectedPII.first?.pattern.name, "PAN")
        XCTAssertEqual(result.detectedPII.first?.match, "ABCDE1234F")
        XCTAssertEqual(result.severity, .critical)
        XCTAssertTrue(result.cleanedText.contains("***PAN***"))
    }

    // MARK: - Account Number Detection Tests

    func testDetectsAccountNumber() {
        let response = """
        {
          "earnings": {"BPAY": 37000},
          "account": "12345678901"
        }
        """

        let result = scrubber.scrub(response)

        XCTAssertFalse(result.isClean, "Should detect account number")
        XCTAssertEqual(result.detectedPII.count, 1)
        XCTAssertEqual(result.detectedPII.first?.pattern.name, "Account")
        XCTAssertEqual(result.detectedPII.first?.match, "12345678901")
        XCTAssertEqual(result.severity, .critical)
        XCTAssertTrue(result.cleanedText.contains("***Account***"))
    }

    // MARK: - Phone Number Detection Tests

    func testDetectsPhoneNumber() {
        let response = """
        {
          "earnings": {"BPAY": 37000},
          "phone": "9876543210"
        }
        """

        let result = scrubber.scrub(response)

        XCTAssertFalse(result.isClean, "Should detect phone number")
        XCTAssertEqual(result.detectedPII.count, 1)
        XCTAssertEqual(result.detectedPII.first?.pattern.name, "Phone")
        XCTAssertEqual(result.detectedPII.first?.match, "9876543210")
        XCTAssertEqual(result.severity, .critical)
        XCTAssertTrue(result.cleanedText.contains("***Phone***"))
    }

    // MARK: - Email Detection Tests

    func testDetectsEmail() {
        let response = """
        {
          "earnings": {"BPAY": 37000},
          "email": "user@example.com"
        }
        """

        let result = scrubber.scrub(response)

        XCTAssertFalse(result.isClean, "Should detect email")
        XCTAssertEqual(result.detectedPII.count, 1)
        XCTAssertEqual(result.detectedPII.first?.pattern.name, "Email")
        XCTAssertEqual(result.detectedPII.first?.match, "user@example.com")
        XCTAssertEqual(result.severity, .warning)
        XCTAssertTrue(result.cleanedText.contains("***Email***"))
    }

    // MARK: - Name Detection Tests

    func testDetectsPossibleName() {
        let response = """
        {
          "earnings": {"BPAY": 37000},
          "name": "Name: John Doe"
        }
        """

        let result = scrubber.scrub(response)

        XCTAssertFalse(result.isClean, "Should detect possible name")
        XCTAssertEqual(result.detectedPII.count, 1)
        XCTAssertEqual(result.detectedPII.first?.pattern.name, "PossibleName")
        XCTAssertEqual(result.severity, .warning)
        XCTAssertTrue(result.cleanedText.contains("***PossibleName***"))
    }

    // MARK: - Severity Tests

    func testCriticalSeverityForPAN() {
        let response = "PAN: ABCDE1234F"
        let result = scrubber.scrub(response)
        XCTAssertEqual(result.severity, .critical)
    }

    func testCriticalSeverityForAccount() {
        let response = "Account: 12345678901"
        let result = scrubber.scrub(response)
        XCTAssertEqual(result.severity, .critical)
    }

    func testCriticalSeverityForPhone() {
        let response = "Phone: 9876543210"
        let result = scrubber.scrub(response)
        XCTAssertEqual(result.severity, .critical)
    }

    func testWarningSeverityForName() {
        let response = "Name: John Doe"
        let result = scrubber.scrub(response)
        XCTAssertEqual(result.severity, .warning)
    }

    func testWarningSeverityForEmail() {
        let response = "Email: user@example.com"
        let result = scrubber.scrub(response)
        XCTAssertEqual(result.severity, .warning)
    }

    // MARK: - Clean Response Tests

    func testCleanResponsePassesThrough() {
        let response = """
        {
          "earnings": {"BPAY": 37000, "DA": 24200},
          "deductions": {"DSOP": 2220, "ITAX": 15585},
          "grossPay": 61200,
          "totalDeductions": 17805,
          "netRemittance": 43395,
          "month": "AUGUST",
          "year": 2025
        }
        """

        let result = scrubber.scrub(response)

        XCTAssertTrue(result.isClean, "Clean response should pass through")
        XCTAssertEqual(result.detectedPII.count, 0)
        XCTAssertEqual(result.severity, .clean)
        XCTAssertEqual(result.cleanedText, response, "Clean text should be unchanged")
    }

    // MARK: - Edge Cases

    func testEmptyResponse() {
        let response = ""
        let result = scrubber.scrub(response)

        XCTAssertTrue(result.isClean)
        XCTAssertEqual(result.detectedPII.count, 0)
        XCTAssertEqual(result.severity, .clean)
    }

    func testResponseWithOnlyWhitespace() {
        let response = "   \n\t  "
        let result = scrubber.scrub(response)

        XCTAssertTrue(result.isClean)
        XCTAssertEqual(result.detectedPII.count, 0)
        XCTAssertEqual(result.severity, .clean)
    }
}
