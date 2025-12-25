//
//  LLMResponsePIIScubberTests.swift
//  PayslipMaxTests
//
//  Tests for PII scrubber functionality
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

    func testDetectsMultiplePANs() {
        let response = "PAN1: ABCDE1234F, PAN2: XYZAB5678C"

        let result = scrubber.scrub(response)

        XCTAssertFalse(result.isClean)
        XCTAssertEqual(result.detectedPII.count, 2)
        XCTAssertEqual(result.severity, .critical)
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

    func testDetectsLongAccountNumber() {
        let response = "Account: 12345678901234"

        let result = scrubber.scrub(response)

        XCTAssertFalse(result.isClean)
        XCTAssertEqual(result.detectedPII.count, 1)
        XCTAssertEqual(result.severity, .critical)
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

    func testIgnoresInvalidPhoneNumbers() {
        // Phone numbers starting with 0-5 are invalid in India
        let response = "Contact: 1234567890"

        let result = scrubber.scrub(response)

        // Should not detect as phone (starts with 1, not 6-9)
        let phoneDetected = result.detectedPII.contains { $0.pattern.name == "Phone" }
        XCTAssertFalse(phoneDetected, "Should not detect invalid phone pattern")
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

    func testDetectsEmployeeName() {
        let response = "Employee: Jane Smith"

        let result = scrubber.scrub(response)

        XCTAssertFalse(result.isClean)
        let nameDetected = result.detectedPII.contains { $0.pattern.name == "PossibleName" }
        XCTAssertTrue(nameDetected)
        XCTAssertEqual(result.severity, .warning)
    }

    // MARK: - Known Pay Code Tests

    func testIgnoresKnownPayCodes() {
        let response = """
        {
          "earnings": {
            "BPAY": 37000,
            "DA": 24200,
            "MSP": 5200,
            "TA": 1200,
            "HRA": 8500,
            "CCA": 2400,
            "NPS": 3200,
            "GPF": 4500
          },
          "deductions": {
            "DSOP": 2220,
            "DSOPP": 1500,
            "AGIF": 7500,
            "ITAX": 15585,
            "CGHS": 500,
            "AFPP": 1000
          }
        }
        """

        let result = scrubber.scrub(response)

        XCTAssertTrue(result.isClean, "Should not detect pay codes as PII")
        XCTAssertEqual(result.detectedPII.count, 0)
        XCTAssertEqual(result.severity, .clean)
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

    // MARK: - Multiple PII Detection Tests

    func testMultiplePIIDetection() {
        let response = """
        {
          "pan": "ABCDE1234F",
          "account": "12345678901",
          "phone": "9876543210",
          "email": "user@example.com",
          "name": "Name: John Doe"
        }
        """

        let result = scrubber.scrub(response)

        XCTAssertFalse(result.isClean)
        XCTAssertEqual(result.detectedPII.count, 5)
        XCTAssertEqual(result.severity, .critical, "Should be critical when PAN/account/phone present")

        // Verify all PII types detected
        let detectedTypes = Set(result.detectedPII.map { $0.pattern.name })
        XCTAssertTrue(detectedTypes.contains("PAN"))
        XCTAssertTrue(detectedTypes.contains("Account"))
        XCTAssertTrue(detectedTypes.contains("Phone"))
        XCTAssertTrue(detectedTypes.contains("Email"))
        XCTAssertTrue(detectedTypes.contains("PossibleName"))
    }

    func testMixedPIICriticalSeverity() {
        // Mix of critical (account) and warning (email) should be critical
        let response = "Account: 12345678901, Email: user@example.com"

        let result = scrubber.scrub(response)

        XCTAssertEqual(result.severity, .critical)
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

    func testResponseWithNumbers() {
        // Numbers that are amounts, not account numbers (<10 digits)
        let response = """
        {
          "earnings": {"BPAY": 37000, "DA": 24200},
          "grossPay": 61200
        }
        """

        let result = scrubber.scrub(response)

        XCTAssertTrue(result.isClean, "Should not detect amounts as account numbers")
    }
}
