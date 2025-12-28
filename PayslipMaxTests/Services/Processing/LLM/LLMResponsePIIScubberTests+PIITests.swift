//
//  LLMResponsePIIScubberTests+PIITests.swift
//  PayslipMaxTests
//
//  PII Detection Tests extension
//

import XCTest
@testable import PayslipMax

// MARK: - PII Detection Tests

extension LLMResponsePIIScubberTests {

    func testDetectsMultiplePANs() {
        let response = "PAN1: ABCDE1234F, PAN2: XYZAB5678C"

        let result = scrubber.scrub(response)

        XCTAssertFalse(result.isClean)
        XCTAssertEqual(result.detectedPII.count, 2)
        XCTAssertEqual(result.severity, .critical)
    }

    func testDetectsLongAccountNumber() {
        let response = "Account: 12345678901234"

        let result = scrubber.scrub(response)

        XCTAssertFalse(result.isClean)
        XCTAssertEqual(result.detectedPII.count, 1)
        XCTAssertEqual(result.severity, .critical)
    }

    func testIgnoresInvalidPhoneNumbers() {
        // Phone numbers starting with 0-5 are invalid in India
        let response = "Contact: 1234567890"

        let result = scrubber.scrub(response)

        // Should not detect as phone (starts with 1, not 6-9)
        let phoneDetected = result.detectedPII.contains { $0.pattern.name == "Phone" }
        XCTAssertFalse(phoneDetected, "Should not detect invalid phone pattern")
    }

    func testDetectsEmployeeName() {
        let response = "Employee: Jane Smith"

        let result = scrubber.scrub(response)

        XCTAssertFalse(result.isClean)
        let nameDetected = result.detectedPII.contains { $0.pattern.name == "PossibleName" }
        XCTAssertTrue(nameDetected)
        XCTAssertEqual(result.severity, .warning)
    }

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

