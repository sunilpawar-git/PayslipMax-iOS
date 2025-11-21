//
//  PayslipAnonymizerTests.swift
//  PayslipMaxTests
//
//  Tests for PII redaction before LLM processing
//

import XCTest
@testable import PayslipMax

final class PayslipAnonymizerTests: XCTestCase {

    var anonymizer: PayslipAnonymizer!

    override func setUpWithError() throws {
        try super.setUpWithError()
        anonymizer = try PayslipAnonymizer()
    }

    override func tearDown() {
        anonymizer = nil
        super.tearDown()
    }

    // MARK: - Name Redaction Tests

    func testNameRedaction() throws {
        let input = "Name: Sunil Suresh Pawar"
        let result = try anonymizer.anonymize(input)

        XCTAssertFalse(result.contains("Sunil"), "Name should be redacted")
        XCTAssertFalse(result.contains("Pawar"), "Name should be redacted")
        XCTAssertTrue(result.contains("[REDACTED]"), "Should contain redaction placeholder")
    }

    func testNameWithColonRedaction() throws {
        let input = "Name:Rajesh Kumar"
        let result = try anonymizer.anonymize(input)

        XCTAssertFalse(result.contains("Rajesh"), "Name should be redacted")
        XCTAssertTrue(result.contains("[REDACTED]"), "Should contain redaction placeholder")
    }

    // MARK: - Account Number Redaction Tests

    func testAccountNumberRedaction() throws {
        let input = "A/C No: 16/110/206718K"
        let result = try anonymizer.anonymize(input)

        XCTAssertFalse(result.contains("206718K"), "Account number should be redacted")
        XCTAssertTrue(result.contains("[REDACTED]"), "Should contain redaction placeholder")
    }

    func testAccountNumberWithDifferentFormat() throws {
        let input = "A/C No - 12345/67/890"
        let result = try anonymizer.anonymize(input)

        XCTAssertFalse(result.contains("12345"), "Account number should be redacted")
        XCTAssertTrue(result.contains("[REDACTED]"), "Should contain redaction placeholder")
    }

    // MARK: - PAN Redaction Tests

    func testPANRedaction() throws {
        let input = "PAN No: AR****90G"
        let result = try anonymizer.anonymize(input)

        XCTAssertFalse(result.contains("AR****90G"), "PAN should be redacted")
        XCTAssertTrue(result.contains("[REDACTED]"), "Should contain redaction placeholder")
    }

    func testFullPANRedaction() throws {
        let input = "PAN No: ABCDE1234F"
        let result = try anonymizer.anonymize(input)

        XCTAssertFalse(result.contains("ABCDE1234F"), "PAN should be redacted")
        XCTAssertTrue(result.contains("[REDACTED]"), "Should contain redaction placeholder")
    }

    // MARK: - Phone Redaction Tests

    func testPhoneNumberRedaction() throws {
        let input = "+91 9876543210"
        let result = try anonymizer.anonymize(input)

        XCTAssertFalse(result.contains("9876543210"), "Phone should be redacted")
        XCTAssertTrue(result.contains("[REDACTED]"), "Should contain redaction placeholder")
    }

    func testPhoneWithoutCountryCodeRedaction() throws {
        let input = "Mobile: 8765432109"
        let result = try anonymizer.anonymize(input)

        XCTAssertFalse(result.contains("8765432109"), "Phone should be redacted")
    }

    // MARK: - Email Redaction Tests

    func testEmailRedaction() throws {
        let input = "Email: user@example.com"
        let result = try anonymizer.anonymize(input)

        XCTAssertFalse(result.contains("user@example.com"), "Email should be redacted")
        XCTAssertTrue(result.contains("[EMAIL]"), "Should contain email placeholder")
    }

    // MARK: - Location Redaction Tests

    func testLocationRedaction() throws {
        let input = "Location: Pune, Maharashtra"
        let result = try anonymizer.anonymize(input)

        XCTAssertTrue(result.contains("[LOCATION]"), "Should contain location placeholder")
    }

    // MARK: - Payslip Component Preservation Tests

    func testPayComponentsNotRedacted() throws {
        let input = """
        BPAY (12A): 144700
        DA: 88110
        MSP: 15500
        DSOP: 40000
        Gross Pay: 276365
        """

        let result = try anonymizer.anonymize(input)

        // Pay codes and amounts should be preserved
        XCTAssertTrue(result.contains("BPAY"), "Pay codes should not be redacted")
        XCTAssertTrue(result.contains("144700"), "Amounts should not be redacted")
        XCTAssertTrue(result.contains("DA"), "Pay codes should not be redacted")
        XCTAssertTrue(result.contains("88110"), "Amounts should not be redacted")
        XCTAssertTrue(result.contains("Gross Pay"), "Totals label should not be redacted")
    }

    // MARK: - Full Payslip Test

    func testFullPayslipAnonymization() throws {
        let input = """
        Principal Controller of Defence Accounts (Officers),Pune
        STATEMENT OF ACCOUNT FOR 06/2025

        Name: Sunil Suresh Pawar
        A/C No: 16/110/206718K
        PAN No: AR****90G

        EARNINGS (₹)
        BPAY (12A): 144700
        DA: 88110
        MSP: 15500

        DEDUCTIONS (₹)
        DSOP: 40000
        AGIF: 12500
        ITAX: 46687

        Gross Pay: 276365
        Total Deductions: 101054
        Net Remittance: Rs.1,75,311
        """

        let result = try anonymizer.anonymize(input)

        // PII should be redacted
        XCTAssertFalse(result.contains("Sunil"), "Name should be redacted")
        XCTAssertFalse(result.contains("16/110/206718K"), "Full A/C number should be redacted")
        XCTAssertFalse(result.contains("AR****90G"), "PAN should be redacted")

        // Pay components should be preserved
        XCTAssertTrue(result.contains("BPAY"), "Pay codes preserved")
        XCTAssertTrue(result.contains("144700"), "Amounts preserved")
        XCTAssertTrue(result.contains("Gross Pay"), "Labels preserved")
        XCTAssertTrue(result.contains("276365"), "Totals preserved")

        // Verify redaction count
        XCTAssertGreaterThan(anonymizer.lastRedactionCount, 0, "Should have redacted at least one field")
    }

    // MARK: - Validation Tests

    func testValidationOfAnonymizedText() throws {
        let input = """
        Name: John Doe
        A/C No: 12345/67/890
        PAN No: ABCDE1234F
        BPAY: 100000
        """

        let anonymized = try anonymizer.anonymize(input)
        let isValid = anonymizer.validate(anonymized)

        XCTAssertTrue(isValid, "Anonymized text should pass validation")
    }

    func testValidationFailsForUnanonymizedText() {
        let input = """
        Name: John Doe
        BPAY: 100000
        """

        let isValid = anonymizer.validate(input)

        XCTAssertFalse(isValid, "Validation should fail for text with PII")
    }

    // MARK: - Error Handling Tests

    func testEmptyStringThrowsError() {
        XCTAssertThrowsError(try anonymizer.anonymize("")) { error in
            guard let anonymizationError = error as? AnonymizationError else {
                XCTFail("Expected AnonymizationError")
                return
            }

            if case .noTextProvided = anonymizationError {
                // Success
            } else {
                XCTFail("Expected .noTextProvided error")
            }
        }
    }

    func testTextTooLargeThrowsError() {
        // Create a configuration with small limit
        let config = AnonymizerConfiguration(
            redactionPlaceholder: "X",
            emailPlaceholder: "E",
            locationPlaceholder: "L",
            maxTextSize: 10
        )
        // Force try is acceptable in test setup if we expect it to succeed
        let smallAnonymizer = try! PayslipAnonymizer(configuration: config)

        let largeText = "This text is definitely longer than 10 characters"

        XCTAssertThrowsError(try smallAnonymizer.anonymize(largeText)) { error in
            guard let anonymizationError = error as? AnonymizationError else {
                XCTFail("Expected AnonymizationError")
                return
            }

            if case .textTooLarge = anonymizationError {
                // Success
            } else {
                XCTFail("Expected .textTooLarge error")
            }
        }
    }

    func testStringWithNoPII() throws {
        let input = "BPAY: 100000\nDA: 50000\nGross Pay: 150000"
        let result = try anonymizer.anonymize(input)

        XCTAssertEqual(result, input, "Text without PII should remain unchanged")
        XCTAssertEqual(anonymizer.lastRedactionCount, 0, "Should have zero redactions")
    }
}
