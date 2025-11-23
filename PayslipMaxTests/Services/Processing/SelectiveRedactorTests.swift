//
//  SelectiveRedactorTests.swift
//  PayslipMaxTests
//
//  Tests for selective PII redaction
//

import XCTest
@testable import PayslipMax

final class SelectiveRedactorTests: XCTestCase {

    var sut: SelectiveRedactor!

    override func setUp() {
        super.setUp()
        sut = try! SelectiveRedactor()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Basic Redaction Tests

    func testRedactsNameField() throws {
        // Given
        let input = """
        Name: Sunil Pawar
        Service No: 12345
        """

        // When
        let result = try sut.redact(input)

        // Then
        XCTAssertTrue(result.contains("***NAME***"), "Should redact name")
        XCTAssertFalse(result.contains("Sunil Pawar"), "Should not contain original name")
        XCTAssertTrue(result.contains("Service No: 12345"), "Should preserve service number")
    }

    func testRedactsAccountNumber() throws {
        // Given
        let input = """
        A/C No: 16/110/206718K
        BPAY: 172986
        """

        // When
        let result = try sut.redact(input)

        // Then
        XCTAssertTrue(result.contains("***ACCOUNT***"), "Should redact account number")
        XCTAssertFalse(result.contains("16/110/206718K"), "Should not contain original account")
        XCTAssertTrue(result.contains("BPAY: 172986"), "Should preserve BPAY amount")
    }

    func testRedactsPANNumber() throws {
        // Given
        let input = """
        PAN No: AR****90G
        DSOP: 8649
        """

        // When
        let result = try sut.redact(input)

        // Then
        XCTAssertTrue(result.contains("***PAN***"), "Should redact PAN")
        XCTAssertFalse(result.contains("AR****90G"), "Should not contain original PAN")
        XCTAssertTrue(result.contains("DSOP: 8649"), "Should preserve DSOP")
    }

    func testRedactsPhoneNumber() throws {
        // Given
        let input = """
        Contact: +91 9876543210
        MSP: 15800
        """

        // When
        let result = try sut.redact(input)

        // Then
        XCTAssertTrue(result.contains("***PHONE***"), "Should redact phone")
        XCTAssertFalse(result.contains("9876543210"), "Should not contain original phone")
        XCTAssertTrue(result.contains("MSP: 15800"), "Should preserve MSP")
    }

    func testRedactsEmail() throws {
        // Given
        let input = """
        Email: sunil@example.com
        ITAX: 12000
        """

        // When
        let result = try sut.redact(input)

        // Then
        XCTAssertTrue(result.contains("***EMAIL***"), "Should redact email")
        XCTAssertFalse(result.contains("sunil@example.com"), "Should not contain original email")
        XCTAssertTrue(result.contains("ITAX: 12000"), "Should preserve income tax")
    }

    // MARK: - Pay Code Preservation Tests

    func testPreservesCommonPayCodes() throws {
        // Given
        let input = """
        Name: John Doe
        BPAY: 172986
        DA: 93000
        MSP: 15800
        DSOP: 8649
        AGIF: 5400
        ITAX: 12000
        """

        // When
        let result = try sut.redact(input)

        // Then
        XCTAssertTrue(result.contains("BPAY: 172986"), "Should preserve BPAY")
        XCTAssertTrue(result.contains("DA: 93000"), "Should preserve DA")
        XCTAssertTrue(result.contains("MSP: 15800"), "Should preserve MSP")
        XCTAssertTrue(result.contains("DSOP: 8649"), "Should preserve DSOP")
        XCTAssertTrue(result.contains("AGIF: 5400"), "Should preserve AGIF")
        XCTAssertTrue(result.contains("ITAX: 12000"), "Should preserve ITAX")
        XCTAssertTrue(result.contains("***NAME***"), "Should redact name")
    }

    func testPreservesStructure() throws {
        // Given
        let input = """
        Statement Period: JUNE 2025
        Name: Jane Smith

        EARNINGS:
        BPAY: 172986
        DA: 93000

        DEDUCTIONS:
        DSOP: 8649
        ITAX: 12000

        Total: 257337
        """

        // When
        let result = try sut.redact(input)

        // Then
        XCTAssertTrue(result.contains("Statement Period: JUNE 2025"), "Should preserve date")
        XCTAssertTrue(result.contains("EARNINGS:"), "Should preserve section headers")
        XCTAssertTrue(result.contains("DEDUCTIONS:"), "Should preserve section headers")
        XCTAssertTrue(result.contains("Total: 257337"), "Should preserve totals")
        XCTAssertTrue(result.contains("***NAME***"), "Should redact name")
    }

    // MARK: - Edge Cases

    func testHandlesEmptyText() {
        // Given
        let input = ""

        // When/Then
        XCTAssertThrowsError(try sut.redact(input)) { error in
            XCTAssertTrue(error is AnonymizationError)
        }
    }

    func testHandlesTextWithNoPII() throws {
        // Given
        let input = """
        BPAY: 172986
        DA: 93000
        DSOP: 8649
        """

        // When
        let result = try sut.redact(input)

        // Then
        XCTAssertEqual(result, input, "Should not modify text with no PII")
        XCTAssertEqual(sut.lastRedactionReport?.redactionCount, 0, "Should report zero redactions")
    }

    func testHandlesMultipleOccurrences() throws {
        // Given
        let input = """
        Name: John Doe
        Spouse Name: Jane Doe
        A/C No: 123456
        Joint A/C No: 789012
        """

        // When
        let result = try sut.redact(input)

        // Then
        XCTAssertFalse(result.contains("John Doe"), "Should redact first name")
        XCTAssertFalse(result.contains("Jane Doe"), "Should redact second name")
        XCTAssertFalse(result.contains("123456"), "Should redact first account")
        XCTAssertFalse(result.contains("789012"), "Should redact second account")
        XCTAssertTrue(sut.lastRedactionReport!.redactionCount >= 4, "Should report multiple redactions")
    }

    // MARK: - Redaction Report Tests

    func testGeneratesRedactionReport() throws {
        // Given
        let input = """
        Name: Test User
        A/C No: 12345
        BPAY: 172986
        DSOP: 8649
        """

        // When
        _ = try sut.redact(input)

        // Then
        let report = sut.lastRedactionReport
        XCTAssertNotNil(report, "Should generate report")
        XCTAssertTrue(report!.successful, "Should be successful")
        XCTAssertTrue(report!.redactionCount > 0, "Should have redactions")
        XCTAssertTrue(report!.redactedFields.contains("Name"), "Should report name redaction")
        XCTAssertTrue(report!.redactedFields.contains("Account Number"), "Should report account redaction")
    }

    func testReportIncludesPreservedPayCodes() throws {
        // Given
        let input = """
        Name: Test User
        BPAY: 172986
        DA: 93000
        MSP: 15800
        """

        // When
        _ = try sut.redact(input)

        // Then
        let report = sut.lastRedactionReport
        XCTAssertNotNil(report)
        XCTAssertTrue(report!.preservedPayCodes.contains("BPAY"), "Should report preserved BPAY")
        XCTAssertTrue(report!.preservedPayCodes.contains("DA"), "Should report preserved DA")
        XCTAssertTrue(report!.preservedPayCodes.contains("MSP"), "Should report preserved MSP")
    }

    // MARK: - Real-world Scenario Tests

    func testRealPayslipScenario() throws {
        // Given - Realistic payslip excerpt
        let input = """
        INDIAN ARMY
        STATEMENT OF PAY & ALLOWANCES

        Name: SUNIL PAWAR
        Rank: Major
        A/C No: 16/110/206718K
        PAN No: AR****90G

        Period: JUNE 2025

        EARNINGS                    AMOUNT
        BPAY (12A)                  172986
        DA                          93000
        MSP                         15800
        X Group Pay                 6200

        DEDUCTIONS                  AMOUNT
        DSOP                        8649
        AGIF                        5400
        ITAX                        12000
        CGHS                        500

        GROSS PAY: 288486
        TOTAL DEDUCTIONS: 26549
        NET REMITTANCE: 261937
        """

        // When
        let result = try sut.redact(input)

        // Then - PII redacted
        XCTAssertFalse(result.contains("SUNIL PAWAR"), "Should redact name")
        XCTAssertFalse(result.contains("16/110/206718K"), "Should redact account")
        XCTAssertFalse(result.contains("AR****90G"), "Should redact PAN")

        // Structure preserved
        XCTAssertTrue(result.contains("INDIAN ARMY"), "Should preserve header")
        XCTAssertTrue(result.contains("STATEMENT OF PAY & ALLOWANCES"), "Should preserve title")
        XCTAssertTrue(result.contains("Period: JUNE 2025"), "Should preserve period")
        XCTAssertTrue(result.contains("EARNINGS"), "Should preserve section")
        XCTAssertTrue(result.contains("DEDUCTIONS"), "Should preserve section")

        // Pay codes preserved
        XCTAssertTrue(result.contains("BPAY (12A)                  172986"), "Should preserve BPAY line")
        XCTAssertTrue(result.contains("DA                          93000"), "Should preserve DA line")
        XCTAssertTrue(result.contains("MSP                         15800"), "Should preserve MSP line")
        XCTAssertTrue(result.contains("DSOP                        8649"), "Should preserve DSOP line")

        // Totals preserved
        XCTAssertTrue(result.contains("GROSS PAY: 288486"), "Should preserve gross")
        XCTAssertTrue(result.contains("NET REMITTANCE: 261937"), "Should preserve net")
    }
}
