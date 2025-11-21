//
//  LLMPayslipParserTests.swift
//  PayslipMaxTests
//
//  Tests for LLMPayslipParser
//

import XCTest
@testable import PayslipMax

final class LLMPayslipParserTests: XCTestCase {

    var parser: LLMPayslipParser!
    var mockService: MockLLMService!
    var mockAnonymizer: MockPayslipAnonymizer!

    override func setUp() {
        super.setUp()
        mockService = MockLLMService()
        mockAnonymizer = MockPayslipAnonymizer()
        parser = LLMPayslipParser(service: mockService, anonymizer: mockAnonymizer)
    }

    override func tearDown() {
        parser = nil
        mockService = nil
        mockAnonymizer = nil
        super.tearDown()
    }

    func testParseSuccess() async throws {
        // Setup mock response
        let json = """
        {
            "earnings": {"BPAY": 1000.0, "DA": 500.0},
            "deductions": {"DSOP": 200.0, "ITAX": 100.0},
            "grossPay": 1500.0,
            "totalDeductions": 300.0,
            "netRemittance": 1200.0,
            "month": "JUNE",
            "year": 2025
        }
        """
        mockService.mockResponse = json

        let result = try await parser.parse("Raw Payslip Text")

        // Verify result
        XCTAssertEqual(result.month, "JUNE")
        XCTAssertEqual(result.year, 2025)
        XCTAssertEqual(result.credits, 1500.0) // grossPay
        XCTAssertEqual(result.debits, 300.0) // totalDeductions
        XCTAssertEqual(result.earnings["BPAY"], 1000.0)
        XCTAssertEqual(result.earnings["DA"], 500.0)
        XCTAssertEqual(result.deductions["DSOP"], 200.0)
        XCTAssertEqual(result.deductions["ITAX"], 100.0)
        XCTAssertEqual(result.source, "LLM (mock)")

        // Verify interactions
        XCTAssertEqual(mockService.lastRequest?.prompt, "Payslip Text (anonymized):\nAnonymized: Raw Payslip Text")
    }

    func testParseAnonymizationFailure() async {
        mockAnonymizer.shouldFail = true

        do {
            _ = try await parser.parse("Raw Text")
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is AnonymizationError)
        }
    }

    func testParseLLMFailure() async {
        mockService.shouldFail = true

        do {
            _ = try await parser.parse("Raw Text")
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error is LLMError)
        }
    }

    func testParseDecodingFailure() async {
        mockService.mockResponse = "Invalid JSON"

        do {
            _ = try await parser.parse("Raw Text")
            XCTFail("Should have thrown error")
        } catch {
            if case LLMError.decodingError = error {
                // Success
            } else {
                XCTFail("Expected decodingError, got \(error)")
            }
        }
    }

    func testParsePartialJSONSuccess() async throws {
        // Missing grossPay, totalDeductions, netRemittance
        // But has earnings and deductions
        let json = """
        {
            "earnings": {"BPAY": 1000.0},
            "deductions": {"DSOP": 500.0},
            "month": "JUNE",
            "year": 2025
        }
        """
        mockService.mockResponse = json

        let result = try await parser.parse("Raw Text")

        XCTAssertEqual(result.month, "JUNE")
        XCTAssertEqual(result.credits, 1000.0) // Calculated from earnings
        XCTAssertEqual(result.debits, 500.0) // Calculated from deductions
    }
}
