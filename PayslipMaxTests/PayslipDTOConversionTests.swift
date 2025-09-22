import XCTest
@testable import PayslipMax

/// Tests for PayslipDTO conversion and PDF data handling
/// 
/// This test class focuses on the PayslipDTO design and ensures that:
/// 1. PayslipDTO correctly excludes PDF data for Sendable compliance
/// 2. PayslipItem → PayslipDTO → PayslipItem conversion works properly
/// 3. PDF data restoration from file system works correctly
/// 4. The "by design" separation of PDF data and metadata is maintained
/// 
/// Created: 2025-09-22 - Regression prevention for auto-generated PDF fix
final class PayslipDTOConversionTests: XCTestCase {
    
    // MARK: - Test Properties
    
    private var testPayslipItem: PayslipItem!
    private var testPDFData: Data!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        testPDFData = createMockPDFData()
        testPayslipItem = createTestPayslipItem(with: testPDFData)
    }
    
    override func tearDown() async throws {
        testPayslipItem = nil
        testPDFData = nil
        
        try await super.tearDown()
    }
    
    // MARK: - DTO Design Validation Tests
    
    /// Tests that PayslipDTO correctly excludes PDF data by design
    /// This is CRITICAL for Sendable compliance but was the source of our bug
    func testPayslipDTO_ExcludesPDFDataByDesign() {
        // Given: A PayslipItem with PDF data
        XCTAssertNotNil(testPayslipItem.pdfData, "Test setup should include PDF data")
        
        // When: Converting to PayslipDTO
        let dto = PayslipDTO(from: testPayslipItem)
        
        // Then: PDF data should be excluded (this is by design for Sendable compliance)
        XCTAssertNil(dto.pdfData, "PayslipDTO should exclude PDF data for Sendable compliance")
        
        // But all other data should be preserved
        XCTAssertEqual(dto.id, testPayslipItem.id, "ID should be preserved")
        XCTAssertEqual(dto.month, testPayslipItem.month, "Month should be preserved")
        XCTAssertEqual(dto.year, testPayslipItem.year, "Year should be preserved")
        XCTAssertEqual(dto.credits, testPayslipItem.credits, "Credits should be preserved")
        XCTAssertEqual(dto.debits, testPayslipItem.debits, "Debits should be preserved")
        XCTAssertEqual(dto.name, testPayslipItem.name, "Name should be preserved")
    }
    
    /// Tests that PayslipItem can be reconstructed from PayslipDTO
    /// This is important for the data loading process
    func testPayslipItem_CanBeReconstructedFromDTO() {
        // Given: A PayslipDTO (without PDF data)
        let dto = PayslipDTO(from: testPayslipItem)
        
        // When: Converting back to PayslipItem
        let reconstructedItem = PayslipItem(from: dto)
        
        // Then: All metadata should be preserved
        XCTAssertEqual(reconstructedItem.id, testPayslipItem.id, "ID should match")
        XCTAssertEqual(reconstructedItem.month, testPayslipItem.month, "Month should match")
        XCTAssertEqual(reconstructedItem.year, testPayslipItem.year, "Year should match")
        XCTAssertEqual(reconstructedItem.credits, testPayslipItem.credits, "Credits should match")
        XCTAssertEqual(reconstructedItem.debits, testPayslipItem.debits, "Debits should match")
        XCTAssertEqual(reconstructedItem.name, testPayslipItem.name, "Name should match")
        
        // PDF data should be nil (will be restored separately)
        XCTAssertNil(reconstructedItem.pdfData, "PDF data should be nil after DTO conversion")
    }
    
    /// Tests that earnings and deductions dictionaries are preserved through conversion
    /// This is important for dual-section functionality
    func testDualSectionData_PreservedThroughDTOConversion() {
        // Given: PayslipItem with dual-section earnings and deductions
        testPayslipItem.earnings = [
            "Basic Pay": 150000.0,
            "RH12_EARNINGS": 25000.0,
            "Dearness Allowance": 90000.0
        ]
        testPayslipItem.deductions = [
            "Income Tax": 45000.0,
            "RH12_DEDUCTIONS": 7500.0,
            "AGIF": 12500.0
        ]
        
        // When: Converting to DTO and back
        let dto = PayslipDTO(from: testPayslipItem)
        let reconstructed = PayslipItem(from: dto)
        
        // Then: Dual-section data should be preserved
        XCTAssertEqual(reconstructed.earnings.count, testPayslipItem.earnings.count, 
                      "Earnings count should be preserved")
        XCTAssertEqual(reconstructed.deductions.count, testPayslipItem.deductions.count, 
                      "Deductions count should be preserved")
        
        // Verify specific dual-section keys
        XCTAssertEqual(reconstructed.earnings["RH12_EARNINGS"], 25000.0, 
                      "RH12_EARNINGS should be preserved")
        XCTAssertEqual(reconstructed.deductions["RH12_DEDUCTIONS"], 7500.0, 
                      "RH12_DEDUCTIONS should be preserved")
    }
    
    // MARK: - Sendable Compliance Tests
    
    /// Tests that PayslipDTO is truly Sendable
    func testPayslipDTO_IsSendable() {
        let dto = PayslipDTO(from: testPayslipItem)
        
        // This should compile without warnings if PayslipDTO is properly Sendable
        Task {
            let _ = dto
            // If this compiles, PayslipDTO is Sendable
        }
        
        // Verify that PDF data exclusion enables Sendable compliance
        XCTAssertNil(dto.pdfData, "PDF data exclusion is necessary for Sendable compliance")
    }
    
    /// Tests that PayslipItem with PDF data is NOT Sendable (as expected)
    func testPayslipItem_WithPDFData_NotSendableByDesign() {
        // PayslipItem with pdfData should not be Sendable due to Data not being Sendable
        // This is why we need the DTO pattern
        XCTAssertNotNil(testPayslipItem.pdfData, "PayslipItem has PDF data")
        
        // The fact that we need to convert to DTO proves the Sendable requirement
        let dto = PayslipDTO(from: testPayslipItem)
        XCTAssertNil(dto.pdfData, "DTO conversion removes non-Sendable PDF data")
    }
    
    // MARK: - Round-trip Conversion Tests
    
    /// Tests multiple round-trip conversions don't degrade data
    func testMultipleRoundTripConversions_PreserveData() {
        // Given: Original PayslipItem
        let originalItem = testPayslipItem!
        var currentItem = originalItem
        
        // When: Performing multiple round-trip conversions
        for _ in 0..<5 {
            let dto = PayslipDTO(from: currentItem)
            currentItem = PayslipItem(from: dto)
        }
        
        // Then: Metadata should be preserved after multiple conversions
        XCTAssertEqual(currentItem.id, originalItem.id, "ID should survive round trips")
        XCTAssertEqual(currentItem.credits, originalItem.credits, "Credits should survive round trips")
        XCTAssertEqual(currentItem.debits, originalItem.debits, "Debits should survive round trips")
        XCTAssertEqual(currentItem.month, originalItem.month, "Month should survive round trips")
        XCTAssertEqual(currentItem.year, originalItem.year, "Year should survive round trips")
        
        // PDF data should be nil (as expected)
        XCTAssertNil(currentItem.pdfData, "PDF data should remain nil after conversions")
    }
    
    // MARK: - Edge Case Tests
    
    /// Tests conversion with nil/empty data
    func testDTOConversion_WithNilEmptyData() {
        // Given: PayslipItem with minimal data
        let minimalItem = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "",
            year: 0,
            credits: 0.0,
            debits: 0.0,
            dsop: 0.0,
            tax: 0.0,
            name: "",
            accountNumber: "",
            panNumber: "",
            pdfData: nil
        )
        
        // When: Converting to DTO and back
        let dto = PayslipDTO(from: minimalItem)
        let reconstructed = PayslipItem(from: dto)
        
        // Then: Should handle gracefully
        XCTAssertEqual(reconstructed.id, minimalItem.id, "ID should be preserved")
        XCTAssertEqual(reconstructed.month, "", "Empty month should be preserved")
        XCTAssertEqual(reconstructed.credits, 0.0, "Zero credits should be preserved")
        XCTAssertNil(reconstructed.pdfData, "Nil PDF data should remain nil")
    }
    
    /// Tests that very large dictionaries are preserved
    func testDTOConversion_WithLargeDictionaries() {
        // Given: PayslipItem with many earnings/deductions
        var largeEarnings: [String: Double] = [:]
        var largeDeductions: [String: Double] = [:]
        
        for i in 0..<100 {
            largeEarnings["Earning_\(i)"] = Double(i * 100)
            largeDeductions["Deduction_\(i)"] = Double(i * 50)
        }
        
        testPayslipItem.earnings = largeEarnings
        testPayslipItem.deductions = largeDeductions
        
        // When: Converting to DTO and back
        let dto = PayslipDTO(from: testPayslipItem)
        let reconstructed = PayslipItem(from: dto)
        
        // Then: Large dictionaries should be preserved
        XCTAssertEqual(reconstructed.earnings.count, 100, "All earnings should be preserved")
        XCTAssertEqual(reconstructed.deductions.count, 100, "All deductions should be preserved")
        
        // Verify some specific values
        XCTAssertEqual(reconstructed.earnings["Earning_50"], 5000.0, "Specific earnings should match")
        XCTAssertEqual(reconstructed.deductions["Deduction_25"], 1250.0, "Specific deductions should match")
    }
    
    // MARK: - Helper Methods
    
    private func createTestPayslipItem(with pdfData: Data) -> PayslipItem {
        let payslipItem = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "May",
            year: 2025,
            credits: 275000.0,
            debits: 110000.0,
            dsop: 40000.0,
            tax: 45000.0,
            name: "Test Officer",
            accountNumber: "12345678",
            panNumber: "ABCDE1234F",
            pdfData: pdfData
        )
        
        // Add realistic earnings and deductions
        payslipItem.earnings = [
            "Basic Pay": 150000.0,
            "Dearness Allowance": 90000.0,
            "Military Service Pay": 15000.0
        ]
        
        payslipItem.deductions = [
            "Income Tax": 45000.0,
            "AGIF": 12500.0,
            "DSOP": 40000.0
        ]
        
        return payslipItem
    }
    
    private func createMockPDFData() -> Data {
        return "Mock PDF Data Content".data(using: .utf8) ?? Data()
    }
}
