//
//  PayslipDataValidationTests.swift
//  PayslipMaxTests
//
//  Target 5.2: PayslipData Model Validation for Phase 5 Implementation
//  Tests dual-section compatibility, computed properties, and data integrity
//

import XCTest
@testable import PayslipMax

final class PayslipDataValidationTests: XCTestCase {
    
    override func setUpWithError() throws {
        super.setUp()
    }
    
    override func tearDownWithError() throws {
        super.tearDown()
    }
    
    // MARK: - Universal Dual-Section Key Tests
    
    func testPayslipDataFactoryWithDualSectionKeys() {
        // Test dual-section key compatibility from roadmap examples
        let mockPayslip = createMockPayslipWithDualSectionKeys()
        let payslipData = PayslipData(from: mockPayslip)
        
        // Verify dual-section components are handled correctly
        XCTAssertEqual(payslipData.dearnessPay, 25000.0, "DA should combine DA_EARNINGS + legacy DA")
        XCTAssertEqual(payslipData.agif, 2000.0, "AGIF should be retrieved correctly")
        
        // Verify computed properties work with dual-section data
        let expectedNetAmount = mockPayslip.credits - mockPayslip.debits
        let actualNetAmount = payslipData.calculateNetAmount()
        XCTAssertEqual(actualNetAmount, expectedNetAmount, "Net amount calculation should work with dual-section (expected: \(expectedNetAmount), actual: \(actualNetAmount))")
        
        // Verify allEarnings includes dual-section keys
        XCTAssertEqual(payslipData.allEarnings["DA_EARNINGS"], 15000.0, "allEarnings should contain dual-section earnings keys")
        XCTAssertEqual(payslipData.allDeductions["HRA_DEDUCTIONS"], 5000.0, "allDeductions should contain dual-section deductions keys")
    }
    
    func testUniversalDualSectionValueRetrieval() {
        // Test the enhanced dual-key retrieval system
        let mockPayslip = createComplexDualSectionPayslip()
        let payslipData = PayslipData(from: mockPayslip)
        
        // Test HRA dual-section handling (earnings and recovery scenarios)
        let expectedHRAValue = (mockPayslip.earnings["HRA_EARNINGS"] ?? 0) - (mockPayslip.deductions["HRA_DEDUCTIONS"] ?? 0)
        XCTAssertTrue(payslipData.allEarnings.keys.contains("HRA_EARNINGS") || payslipData.allDeductions.keys.contains("HRA_DEDUCTIONS"), 
                      "HRA dual-section keys should be preserved in PayslipData")
        
        // Test RH12 absolute value calculation
        XCTAssertTrue(payslipData.allEarnings["RH12_EARNINGS"] != nil || payslipData.allDeductions["RH12_DEDUCTIONS"] != nil,
                      "RH12 dual-section keys should be preserved")
    }
    
    func testArrearsWithDualSectionKeys() {
        // Test arrears components with dual-section support
        let mockPayslip = createMockPayslipWithArrearsComponents()
        let payslipData = PayslipData(from: mockPayslip)
        
        // Verify arrears dual-section keys are preserved
        XCTAssertEqual(payslipData.allEarnings["ARR-HRA_EARNINGS"], 1650.0, "Arrears earnings should be preserved")
        XCTAssertEqual(payslipData.allDeductions["ARR-CEA_DEDUCTIONS"], 2000.0, "Arrears deductions should be preserved")
        
        // Verify totals include arrears components
        let totalEarnings = payslipData.allEarnings.values.reduce(0, +)
        let totalDeductions = payslipData.allDeductions.values.reduce(0, +)
        XCTAssertEqual(totalEarnings, payslipData.totalCredits, "Total earnings should match credits")
        XCTAssertEqual(totalDeductions, payslipData.totalDebits, "Total deductions should match debits")
    }
    
    // MARK: - Computed Properties Validation
    
    func testCalculateDerivedFieldsWithDualSection() {
        // Test calculateDerivedFields method with dual-section data
        var payslipData = createEmptyPayslipData()
        
        // Set up complex dual-section earnings and deductions
        payslipData.allEarnings = [
            "BPAY": 50000.0,
            "DA_EARNINGS": 15000.0,
            "HRA_EARNINGS": 12000.0,
            "RH12_EARNINGS": 21125.0
        ]
        
        payslipData.allDeductions = [
            "AGIF": 2000.0,
            "DSOP": 5000.0,
            "HRA_DEDUCTIONS": 5000.0,
            "RH12_DEDUCTIONS": 7518.0
        ]
        
        // Calculate derived fields
        payslipData.calculateDerivedFields()
        
        // Verify totals are calculated correctly
        XCTAssertEqual(payslipData.totalCredits, 98125.0, "Total credits should sum all earnings including dual-section")
        XCTAssertEqual(payslipData.totalDebits, 19518.0, "Total debits should sum all deductions including dual-section")
        XCTAssertEqual(payslipData.netRemittance, 78607.0, "Net remittance should be correct with dual-section processing")
        
        // Verify protocol properties are updated
        XCTAssertEqual(payslipData.credits, payslipData.totalCredits, "Credits should match totalCredits")
        XCTAssertEqual(payslipData.debits, payslipData.totalDebits, "Debits should match totalDebits")
    }
    
    func testNetIncomeCalculationWithDualSection() {
        // Test netIncome computed property with dual-section data
        var payslipData = createPayslipDataWithDualSectionTotals()
        
        // Calculate derived fields to ensure credits/debits are set properly
        payslipData.calculateDerivedFields()
        
        let expectedNetIncome = payslipData.totalCredits - payslipData.totalDebits
        XCTAssertEqual(payslipData.netIncome, expectedNetIncome, "NetIncome should calculate correctly with dual-section data")
        XCTAssertEqual(payslipData.calculateNetAmount(), expectedNetIncome, "calculateNetAmount should match netIncome")
        XCTAssertEqual(payslipData.getNetAmount(), expectedNetIncome, "getNetAmount should match netIncome")
    }
    
    // MARK: - JSON Serialization/Deserialization Tests
    
    func testJSONSerializationWithDualSectionKeys() throws {
        // Test JSON compatibility with dual-section keys
        let originalPayslipData = createPayslipDataWithDualSectionTotals()
        
        // Encode to JSON
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(originalPayslipData)
        
        // Decode from JSON
        let decoder = JSONDecoder()
        let decodedPayslipData = try decoder.decode(PayslipData.self, from: jsonData)
        
        // Verify dual-section keys are preserved
        XCTAssertEqual(decodedPayslipData.allEarnings["RH12_EARNINGS"], originalPayslipData.allEarnings["RH12_EARNINGS"], 
                       "Dual-section earnings keys should survive JSON serialization")
        XCTAssertEqual(decodedPayslipData.allDeductions["RH12_DEDUCTIONS"], originalPayslipData.allDeductions["RH12_DEDUCTIONS"], 
                       "Dual-section deductions keys should survive JSON serialization")
        
        // Verify computed properties work after deserialization
        XCTAssertEqual(decodedPayslipData.netIncome, originalPayslipData.netIncome, 
                       "NetIncome should be consistent after JSON round-trip")
    }
    
    // MARK: - Backward Compatibility Tests
    
    func testBackwardCompatibilityWithLegacyKeys() {
        // Test that legacy single keys still work alongside dual-section keys
        let mockPayslip = createMockPayslipWithMixedKeys()
        let payslipData = PayslipData(from: mockPayslip)
        
        // Verify legacy keys are handled
        XCTAssertEqual(payslipData.basicPay, 50000.0, "Legacy BPAY should work")
        XCTAssertEqual(payslipData.militaryServicePay, 15500.0, "Legacy MSP should work")
        
        // Verify dual-section keys are handled
        XCTAssertTrue(payslipData.allEarnings.keys.contains("DA_EARNINGS") || payslipData.dearnessPay > 0, 
                      "DA dual-section should work alongside legacy")
        
        // Verify no data loss
        let totalInput = mockPayslip.credits
        let totalProcessed = payslipData.totalCredits
        XCTAssertEqual(totalInput, totalProcessed, "No data should be lost in mixed key processing")
    }
    
    // MARK: - Helper Methods
    
    private func createMockPayslipWithDualSectionKeys() -> MockPayslip {
        return MockPayslip(
            id: UUID(),
            timestamp: Date(),
            month: "May",
            year: 2025,
            credits: 98125.0,
            debits: 19518.0,
            dsop: 5000.0,
            tax: 8000.0,
            earnings: [
                "BPAY": 50000.0,
                "DA_EARNINGS": 15000.0,
                "Dearness Allowance": 10000.0,  // Legacy + dual-section
                "MSP": 15500.0,
                "RH12_EARNINGS": 21125.0
            ],
            deductions: [
                "AGIF": 2000.0,
                "DSOP": 5000.0,
                "ITAX": 8000.0,
                "HRA_DEDUCTIONS": 5000.0,
                "RH12_DEDUCTIONS": 7518.0
            ],
            name: "Test Officer",
            accountNumber: "XXXX1234",
            panNumber: "ABCDE1234F",
            pdfData: nil,
            isSample: true,
            source: "Test",
            status: "Active"
        )
    }
    
    private func createComplexDualSectionPayslip() -> MockPayslip {
        return MockPayslip(
            id: UUID(),
            timestamp: Date(),
            month: "June",
            year: 2025,
            credits: 125000.0,
            debits: 25000.0,
            dsop: 5000.0,
            tax: 10000.0,
            earnings: [
                "BPAY": 60000.0,
                "DA_EARNINGS": 18000.0,
                "MSP": 17000.0,
                "HRA_EARNINGS": 15000.0,
                "CEA_EARNINGS": 3375.0,
                "RH12_EARNINGS": 11625.0
            ],
            deductions: [
                "AGIF": 2500.0,
                "DSOP": 5000.0,
                "ITAX": 10000.0,
                "HRA_DEDUCTIONS": 2500.0,
                "CEA_DEDUCTIONS": 1000.0,
                "RH12_DEDUCTIONS": 4000.0
            ],
            name: "Complex Test Officer",
            accountNumber: "XXXX5678",
            panNumber: "FGHIJ5678K",
            pdfData: nil,
            isSample: true,
            source: "Test",
            status: "Active"
        )
    }
    
    private func createMockPayslipWithArrearsComponents() -> MockPayslip {
        return MockPayslip(
            id: UUID(),
            timestamp: Date(),
            month: "July",
            year: 2025,
            credits: 85000.0,
            debits: 20000.0,
            dsop: 5000.0,
            tax: 8000.0,
            earnings: [
                "BPAY": 55000.0,
                "DA": 16000.0,
                "MSP": 12350.0,
                "ARR-HRA_EARNINGS": 1650.0
            ],
            deductions: [
                "AGIF": 2000.0,
                "DSOP": 5000.0,
                "ITAX": 8000.0,
                "ARR-CEA_DEDUCTIONS": 2000.0,
                "UTILITIES": 3000.0
            ],
            name: "Arrears Test Officer",
            accountNumber: "XXXX9876",
            panNumber: "KLMNO9876P",
            pdfData: nil,
            isSample: true,
            source: "Test",
            status: "Active"
        )
    }
    
    private func createEmptyPayslipData() -> PayslipData {
        return PayslipData()
    }
    
    private func createPayslipDataWithDualSectionTotals() -> PayslipData {
        var data = PayslipData()
        data.totalCredits = 105000.0
        data.totalDebits = 22000.0
        data.credits = 105000.0  // Set protocol property
        data.debits = 22000.0    // Set protocol property
        data.netRemittance = 83000.0
        data.allEarnings = [
            "BPAY": 55000.0,
            "DA_EARNINGS": 18000.0,
            "MSP": 16000.0,
            "RH12_EARNINGS": 16000.0
        ]
        data.allDeductions = [
            "AGIF": 2500.0,
            "DSOP": 5500.0,
            "ITAX": 9000.0,
            "RH12_DEDUCTIONS": 5000.0
        ]
        // Set earnings and deductions for protocol compatibility
        data.earnings = data.allEarnings
        data.deductions = data.allDeductions
        return data
    }
    
    private func createMockPayslipWithMixedKeys() -> MockPayslip {
        return MockPayslip(
            id: UUID(),
            timestamp: Date(),
            month: "August",
            year: 2025,
            credits: 95000.0,
            debits: 18000.0,
            dsop: 5000.0,
            tax: 8000.0,
            earnings: [
                "BPAY": 50000.0,  // Legacy key
                "DA_EARNINGS": 12000.0,  // Dual-section key
                "Dearness Allowance": 8000.0,  // Legacy display key
                "MSP": 15500.0,  // Legacy key
                "HRA_EARNINGS": 9500.0  // Dual-section key
            ],
            deductions: [
                "AGIF": 2000.0,  // Legacy key
                "DSOP": 5000.0,  // Legacy key
                "ITAX": 8000.0,  // Legacy key
                "HRA_DEDUCTIONS": 3000.0  // Dual-section key
            ],
            name: "Mixed Keys Test Officer",
            accountNumber: "XXXX4321",
            panNumber: "PQRST4321U",
            pdfData: nil,
            isSample: true,
            source: "Test",
            status: "Active"
        )
    }
}

// MARK: - Mock PayslipProtocol Implementation

private struct MockPayslip: PayslipProtocol {
    let id: UUID
    var timestamp: Date
    var month: String
    var year: Int
    var credits: Double
    var debits: Double
    var dsop: Double
    var tax: Double
    var earnings: [String: Double]
    var deductions: [String: Double]
    var name: String
    var accountNumber: String
    var panNumber: String
    var isNameEncrypted: Bool = false
    var isAccountNumberEncrypted: Bool = false
    var isPanNumberEncrypted: Bool = false
    var pdfData: Data?
    var pdfURL: URL? = nil
    var isSample: Bool
    var source: String
    var status: String
    var notes: String? = nil
    
    func calculateNetAmount() -> Double {
        return credits - debits
    }
    
    func getFullDescription() -> String {
        return "Mock Payslip for \(name) - \(month) \(year)"
    }
    
    func encryptSensitiveData() async throws {
        // Mock implementation
    }
    
    func decryptSensitiveData() async throws {
        // Mock implementation
    }
}
