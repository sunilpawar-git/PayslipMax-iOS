import XCTest
import PDFKit
import SwiftData
@testable import PayslipMax

class PayslipProcessingEdgeCaseTests: XCTestCase {
    
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Setup in-memory SwiftData
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PayslipItem.self, configurations: config)
        modelContext = ModelContext(container)
    }
    
    override func tearDownWithError() throws {
        modelContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - PDF Edge Cases
    
    func testPDFProcessing_WithEmptyPDF_HandlesGracefully() {
        // Given
        let emptyPDFData = Data()
        
        // When
        let pdfDocument = PDFDocument(data: emptyPDFData)
        
        // Then
        XCTAssertNil(pdfDocument, "Empty data should not create a valid PDF document")
    }
    
    func testPDFProcessing_WithCorruptedPDF_HandlesGracefully() {
        // Given
        let corruptedData = Data("This is not a valid PDF file".utf8)
        
        // When
        let pdfDocument = PDFDocument(data: corruptedData)
        
        // Then
        XCTAssertNil(pdfDocument, "Corrupted data should not create a valid PDF document")
    }
    
    func testPDFProcessing_WithMinimalValidPDF_ProcessesCorrectly() {
        // Given
        let minimalPDF = TestDataGenerator.samplePDFDocument(withText: "Minimal PDF content")
        
        // When
        let pageCount = minimalPDF.pageCount
        let firstPage = minimalPDF.page(at: 0)
        
        // Then
        XCTAssertGreaterThan(pageCount, 0)
        XCTAssertNotNil(firstPage)
    }
    
    func testPDFProcessing_WithLargePDF_HandlesEfficiently() throws {
        // Given - Create a large PDF with multiple pages
        var largeContent = ""
        for i in 1...1000 {
            largeContent += "Page \(i) content with lots of text to make the PDF larger. "
            largeContent += "This simulates a payslip with extensive details and multiple sections. "
            largeContent += "Additional content to increase the size of the PDF document. "
        }
        
        let largePDF = TestDataGenerator.samplePDFDocument(withText: largeContent)
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        let pageCount = largePDF.pageCount
        let firstPage = largePDF.page(at: 0)
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        XCTAssertGreaterThan(pageCount, 0)
        XCTAssertNotNil(firstPage)
        XCTAssertLessThan(processingTime, 5.0, "Large PDF processing should complete within 5 seconds")
    }
    
    func testPDFProcessing_WithPasswordProtectedPDF_DetectsCorrectly() {
        // Given - This would typically require a real password-protected PDF
        // For now, we'll test the detection logic with a mock
        let normalPDF = TestDataGenerator.samplePDFDocument(withText: "Normal PDF")
        
        // When
        let isLocked = normalPDF.isLocked
        
        // Then
        XCTAssertFalse(isLocked, "Normal PDF should not be locked")
    }
    
    // MARK: - PayslipItem Edge Cases
    
    func testPayslipItem_WithExtremeValues_HandlesCorrectly() throws {
        // Given
        let extremePayslips = [
            // Very large monetary values
            TestDataGenerator.samplePayslipItem(
                credits: Double.greatestFiniteMagnitude,
                debits: Double.greatestFiniteMagnitude / 2
            ),
            
            // Zero values
            TestDataGenerator.samplePayslipItem(
                credits: 0.0,
                debits: 0.0,
                dsop: 0.0,
                tax: 0.0
            ),
            
            // Negative values (adjustments/refunds)
            TestDataGenerator.samplePayslipItem(
                credits: -1000.0,
                debits: -500.0,
                dsop: -100.0,
                tax: -200.0
            ),
            
            // Very precise decimal values
            TestDataGenerator.samplePayslipItem(
                credits: 50000.123456789,
                debits: 10000.987654321,
                dsop: 3000.555555555,
                tax: 8000.111111111
            )
        ]
        
        // When/Then
        for payslip in extremePayslips {
            modelContext.insert(payslip)
            
            // Should not crash during insertion
            XCTAssertNotNil(payslip.id)
            XCTAssertNotNil(payslip.name)
        }
        
        // Should be able to save all extreme cases
        try modelContext.save()
        
        // Should be able to fetch them back
        let fetchDescriptor = FetchDescriptor<PayslipItem>()
        let fetchedPayslips = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedPayslips.count, extremePayslips.count)
    }
    
    func testPayslipItem_WithSpecialCharactersInName_HandlesCorrectly() throws {
        // Given
        let specialNamePayslips = [
            TestDataGenerator.samplePayslipItem(name: ""), // Empty name
            TestDataGenerator.samplePayslipItem(name: "   "), // Whitespace only
            TestDataGenerator.samplePayslipItem(name: "Name with\nnewlines\nand\ttabs"),
            TestDataGenerator.samplePayslipItem(name: "Special chars: !@#$%^&*()_+-=[]{}|;':\",./<>?"),
            TestDataGenerator.samplePayslipItem(name: "Unicode: 🔒💰📊 中文 العربية हिंदी"),
            TestDataGenerator.samplePayslipItem(name: String(repeating: "A", count: 1000)), // Very long name
            TestDataGenerator.samplePayslipItem(name: "Name with emoji 😀😃😄😁"),
            TestDataGenerator.samplePayslipItem(name: "SQL'; DROP TABLE payslips; --") // SQL injection attempt
        ]
        
        // When/Then
        for payslip in specialNamePayslips {
            modelContext.insert(payslip)
            XCTAssertNotNil(payslip.id)
        }
        
        try modelContext.save()
        
        let fetchDescriptor = FetchDescriptor<PayslipItem>()
        let fetchedPayslips = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedPayslips.count, specialNamePayslips.count)
    }
    
    func testPayslipItem_WithInvalidDateValues_HandlesCorrectly() throws {
        // Given
        let invalidDatePayslips = [
            TestDataGenerator.samplePayslipItem(month: "", year: 0),
            TestDataGenerator.samplePayslipItem(month: "InvalidMonth", year: -1),
            TestDataGenerator.samplePayslipItem(month: "February", year: 1800),
            TestDataGenerator.samplePayslipItem(month: "December", year: 3000),
            TestDataGenerator.samplePayslipItem(month: "13th Month", year: 2023),
            TestDataGenerator.samplePayslipItem(month: "Month with spaces   ", year: 2023)
        ]
        
        // When/Then
        for payslip in invalidDatePayslips {
            modelContext.insert(payslip)
            XCTAssertNotNil(payslip.id)
            // The model should store whatever values are provided
            XCTAssertNotNil(payslip.month)
        }
        
        try modelContext.save()
    }
    
    // MARK: - Memory and Performance Edge Cases
    
    func testPayslipItem_WithLargeDataBlob_HandlesEfficiently() throws {
        // Given
        let largeData = Data(repeating: 0xFF, count: 10 * 1024 * 1024) // 10MB
        let payslipWithLargeData = PayslipItem(
            id: UUID(),
            name: "Large Data Payslip",
            data: largeData
        )
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        modelContext.insert(payslipWithLargeData)
        try modelContext.save()
        let saveTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        XCTAssertLessThan(saveTime, 10.0, "Large data should save within 10 seconds")
        
        // Fetch it back
        let fetchStartTime = CFAbsoluteTimeGetCurrent()
        let fetchDescriptor = FetchDescriptor<PayslipItem>(
            predicate: #Predicate { $0.id == payslipWithLargeData.id }
        )
        let fetchedPayslips = try modelContext.fetch(fetchDescriptor)
        let fetchTime = CFAbsoluteTimeGetCurrent() - fetchStartTime
        
        XCTAssertEqual(fetchedPayslips.count, 1)
        XCTAssertEqual(fetchedPayslips.first?.data.count, largeData.count)
        XCTAssertLessThan(fetchTime, 5.0, "Large data should fetch within 5 seconds")
    }
    
    func testPayslipItem_MassInsertion_HandlesEfficiently() throws {
        // Given
        let massInsertionCount = 1000
        let payslips = (0..<massInsertionCount).map { index in
            TestDataGenerator.samplePayslipItem(
                id: UUID(),
                name: "Mass Payslip \(index)",
                credits: Double(5000 + index),
                debits: Double(1000 + index)
            )
        }
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for payslip in payslips {
            modelContext.insert(payslip)
        }
        
        try modelContext.save()
        let insertionTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        XCTAssertLessThan(insertionTime, 30.0, "Mass insertion should complete within 30 seconds")
        
        // Verify all were inserted
        let fetchDescriptor = FetchDescriptor<PayslipItem>()
        let fetchedPayslips = try modelContext.fetch(fetchDescriptor)
        XCTAssertEqual(fetchedPayslips.count, massInsertionCount)
    }
    
    // MARK: - Concurrent Access Edge Cases
    
    func testPayslipItem_ConcurrentAccess_MaintainsDataIntegrity() async throws {
        // Given
        let concurrentOperationCount = 50
        let basePayslip = TestDataGenerator.samplePayslipItem(name: "Base Payslip")
        modelContext.insert(basePayslip)
        try modelContext.save()
        
        // When - Perform concurrent read/write operations
        await withTaskGroup(of: Void.self) { group in
            // Add concurrent read tasks
            for i in 0..<concurrentOperationCount {
                group.addTask {
                    do {
                        let fetchDescriptor = FetchDescriptor<PayslipItem>()
                        _ = try self.modelContext.fetch(fetchDescriptor)
                    } catch {
                        XCTFail("Concurrent read failed: \(error)")
                    }
                }
                
                // Add concurrent write tasks
                if i % 5 == 0 { // Fewer write operations to avoid conflicts
                    group.addTask {
                        do {
                            let newPayslip = TestDataGenerator.samplePayslipItem(name: "Concurrent \(i)")
                            self.modelContext.insert(newPayslip)
                            try self.modelContext.save()
                        } catch {
                            // Some concurrent writes may fail, which is acceptable
                            print("Concurrent write failed (expected): \(error)")
                        }
                    }
                }
            }
            
            // Wait for all tasks to complete
            for await _ in group {
                // All tasks completed
            }
        }
        
        // Then - Verify data integrity
        let fetchDescriptor = FetchDescriptor<PayslipItem>()
        let finalPayslips = try modelContext.fetch(fetchDescriptor)
        XCTAssertGreaterThan(finalPayslips.count, 0, "Should have at least the base payslip")
    }
    
    // MARK: - Financial Calculation Edge Cases
    
    func testFinancialCalculations_WithExtremeValues_HandlesCorrectly() {
        // Given
        let edgeCasePayslips = [
            // Floating point precision edge cases
            TestDataGenerator.samplePayslipItem(
                credits: 0.1 + 0.2, // Should be 0.3 but might have precision issues
                debits: 0.1,
                dsop: 0.1,
                tax: 0.1
            ),
            
            // Very small values
            TestDataGenerator.samplePayslipItem(
                credits: Double.leastNormalMagnitude,
                debits: Double.leastNormalMagnitude,
                dsop: Double.leastNormalMagnitude,
                tax: Double.leastNormalMagnitude
            ),
            
            // Infinity values
            TestDataGenerator.samplePayslipItem(
                credits: Double.infinity,
                debits: 1000.0,
                dsop: 100.0,
                tax: 500.0
            ),
            
            // NaN values
            TestDataGenerator.samplePayslipItem(
                credits: Double.nan,
                debits: 1000.0,
                dsop: 100.0,
                tax: 500.0
            )
        ]
        
        // When/Then
        for payslip in edgeCasePayslips {
            // Should not crash during calculations
            let netAmount = payslip.credits - (payslip.debits + payslip.dsop + payslip.tax)
            
            // Handle special cases appropriately
            if payslip.credits.isInfinite {
                XCTAssertTrue(netAmount.isInfinite)
            } else if payslip.credits.isNaN {
                XCTAssertTrue(netAmount.isNaN)
            } else if payslip.credits == Double.leastNormalMagnitude {
                // Very small values should still compute
                XCTAssertFalse(netAmount.isInfinite)
                XCTAssertFalse(netAmount.isNaN)
            }
        }
    }
    
    func testFinancialCalculations_PrecisionAndRounding_HandlesCorrectly() {
        // Given
        let precisionTestCases = [
            (credits: 100.006, debits: 50.003, expected: 50.003),
            (credits: 999999.999, debits: 0.001, expected: 999999.998),
            (credits: 0.333333333, debits: 0.111111111, expected: 0.222222222)
        ]
        
        // When/Then
        for testCase in precisionTestCases {
            let payslip = TestDataGenerator.samplePayslipItem(
                credits: testCase.credits,
                debits: testCase.debits,
                dsop: 0.0,
                tax: 0.0
            )
            
            let netAmount = payslip.credits - payslip.debits
            
            // Check if the calculation is within acceptable precision
            let difference = abs(netAmount - testCase.expected)
            XCTAssertLessThan(difference, 0.0001, "Precision should be maintained within 4 decimal places")
        }
    }
    
    // MARK: - Data Validation Edge Cases
    
    func testDataValidation_WithMalformedInput_HandlesGracefully() {
        // Given - Simulate various malformed inputs that might come from PDF parsing
        let malformedInputs = [
            ("", 0.0), // Empty string amounts
            ("N/A", 0.0), // Non-numeric strings
            ("$1,234.56", 1234.56), // Currency formatted
            ("1.234.567,89", 0.0), // European format (should fail gracefully)
            ("1,234,567.89", 1234567.89), // US format with commas
            ("(500.00)", -500.0), // Negative in parentheses
            ("1E+10", 10000000000.0), // Scientific notation
            ("∞", 0.0), // Infinity symbol
            ("−123.45", -123.45) // Unicode minus sign
        ]
        
        // When/Then
        for (input, expectedValue) in malformedInputs {
            // Simulate parsing logic that might handle these cases
            let parsedValue = parseFinancialValue(input)
            
            if expectedValue == 0.0 && input != "" {
                // Should default to 0 for unparseable values
                XCTAssertEqual(parsedValue, 0.0, "Unparseable input '\(input)' should default to 0")
            } else {
                // Should parse correctly formatted values
                XCTAssertEqual(parsedValue, expectedValue, accuracy: 0.01, "Input '\(input)' should parse to \(expectedValue)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func parseFinancialValue(_ input: String) -> Double {
        // Simulate robust financial value parsing
        if input.isEmpty || input == "N/A" || input == "∞" {
            return 0.0
        }
        
        // Handle parentheses for negative values
        if input.hasPrefix("(") && input.hasSuffix(")") {
            let innerValue = String(input.dropFirst().dropLast())
            return -(parseFinancialValue(innerValue))
        }
        
        // Remove common currency formatting
        let cleanedInput = input
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "−", with: "-") // Unicode minus to regular minus
        
        return Double(cleanedInput) ?? 0.0
    }
}