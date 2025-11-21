//
//  TestMocks.swift
//  PayslipMaxTests
//
//  Helper mocks for integration tests
//

import Foundation
@testable import PayslipMax

// MARK: - Mock Regex Processor
class MockRegexProcessor: PayslipProcessorProtocol {
    var handlesFormat: PayslipFormat = .defense

    func canProcess(text: String) -> Double {
        return 0.5
    }

    func processPayslip(from text: String) async throws -> PayslipItem {
        // Return a basic item to simulate regex parsing
        // For integration tests, we might want this to fail or return low quality
        // to trigger LLM fallback
        return PayslipItem(
            month: "January",
            year: 2024,
            credits: 50000.0,
            debits: 0,
            dsop: 0,
            tax: 0,
            earnings: ["Basic Pay": 50000.0],
            deductions: [:]
        )
    }
}

// MARK: - Mock LLM Parser
class MockLLMParser {
    func parse(_ text: String) async throws -> PayslipItem {
        //Return a high-quality item based on expected values
        let earnings: [String: Double] = [
            "Basic Salary": 50000.0,
            "HRA": 20000.0,
            "Special Allowance": 30000.0,
            "Transport Allowance": 5000.0,
            "Medical Allowance": 1250.0
        ]

        let deductions: [String: Double] = [
            "Provident Fund": 6000.0,
            "Professional Tax": 200.0,
            "Income Tax": 5000.0
        ]

        return PayslipItem(
            month: "June",
            year: 2025,
            credits: 106250.0,
            debits: 11200.0,
            dsop: 0,
            tax: 0,
            earnings: earnings,
            deductions: deductions
        )
    }
}

// MARK: - Mock LLM Parser Adapter
/// Adapter that makes MockLLMParser compatible with LLMPayslipParser for testing
class MockLLMParserAdapter: LLMPayslipParser {
    private let mockParser = MockLLMParser()

    init() {
        // Create mock dependencies for the parent class
        let mockService = MockLLMService()
        let mockAnonymizer = try! PayslipAnonymizer()
        super.init(service: mockService, anonymizer: mockAnonymizer)
    }

    override func parse(_ text: String) async throws -> PayslipItem {
        return try await mockParser.parse(text)
    }
}
