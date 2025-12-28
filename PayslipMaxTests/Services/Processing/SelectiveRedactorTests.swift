//
//  SelectiveRedactorTests.swift
//  PayslipMaxTests
//
//  Tests for selective PII redaction
//  Additional tests in: SelectiveRedactorTests+EdgeCases.swift
//

import XCTest
@testable import PayslipMax

final class SelectiveRedactorTests: XCTestCase {

    var sut: SelectiveRedactor!

    override func setUp() {
        super.setUp()
        sut = SelectiveRedactor()
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
        XCTAssertTrue(result.contains("Service No: ***SERVICE***"), "Should redact service number")
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

    func testRedactsSusNumber() throws {
        // Given
        let input = """
        SUS No.: 0415010
        BPAY: 50000
        """

        // When
        let result = try sut.redact(input)

        // Then
        XCTAssertTrue(result.contains("***SERVICE***"), "Should redact SUS number")
        XCTAssertFalse(result.contains("0415010"), "Should remove original SUS number")
        XCTAssertTrue(result.contains("BPAY: 50000"), "Should preserve pay code")
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
}
