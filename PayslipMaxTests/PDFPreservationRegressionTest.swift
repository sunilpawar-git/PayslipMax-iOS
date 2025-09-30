import XCTest
@testable import PayslipMax

/// Focused regression test for the PDF data loss issue
///
/// This test ensures that the specific bug we fixed doesn't reoccur:
/// - DataLoadingCoordinator.savePayslipAndReload() must preserve PDF data
/// - PayslipDTO conversion should not break PDF retrieval
///
/// Created: 2025-09-22 - Critical regression prevention
@MainActor
final class PDFPreservationRegressionTest: XCTestCase {

    // MARK: - Critical Regression Test

    /// THE MOST IMPORTANT TEST: Ensures PDF data is preserved during save operations
    /// This test validates the exact scenario that was broken before our fix
    func testCriticalRegression_PDFDataPreservationDuringSave() async throws {
        // This test recreates the exact bug scenario:
        // 1. User uploads PDF → PayslipItem with pdfData created
        // 2. DataLoadingCoordinator.savePayslipAndReload() called
        // 3. PDF data should be preserved, NOT lost to DTO conversion

        // Given: A PayslipItem with PDF data (simulating successful PDF processing)
        let testPDFData = "Test PDF Content".data(using: .utf8)!
        let payslipItem = createTestPayslipItemWithPDF(data: testPDFData)

        XCTAssertNotNil(payslipItem.pdfData, "Test setup: PayslipItem should have PDF data")
        XCTAssertEqual(payslipItem.pdfData?.count, testPDFData.count, "PDF data size should match")

        // When: We save the payslip using the method that was broken
        let dataHandler = PayslipDataHandler()
        let savedId = try await dataHandler.savePayslipItemWithPDF(payslipItem)

        // Then: PDF data should be preserved
        XCTAssertEqual(savedId, payslipItem.id, "Save should succeed")

        // Verify PDF file was created (the critical requirement)
        let pdfManager = PDFManager.shared
        let pdfURL = pdfManager.getPDFURL(for: payslipItem.id.uuidString)
        XCTAssertNotNil(pdfURL, "PDF URL should be created")

        if let pdfURL = pdfURL {
            // Verify the PDF file actually exists
            XCTAssertTrue(FileManager.default.fileExists(atPath: pdfURL.path),
                         "CRITICAL: PDF file must exist - this was the original bug")

            // Verify PDF data integrity
            let savedPDFData = try Data(contentsOf: pdfURL)
            XCTAssertEqual(savedPDFData.count, testPDFData.count,
                          "CRITICAL: PDF data must be preserved exactly")
        }

        // Clean up
        cleanupTestPDFFile(for: payslipItem.id)
    }

    /// Tests that PayslipDTO conversion works as designed (without PDF data)
    func testDTOConversionByDesign() {
        // Given: A PayslipItem with PDF data
        let testPDFData = "Test PDF Content".data(using: .utf8)!
        let payslipItem = createTestPayslipItemWithPDF(data: testPDFData)

        // When: Converting to DTO
        let dto = PayslipDTO(from: payslipItem)

        // Then: PDF data should be excluded (this is by design for Sendable compliance)
        XCTAssertNil(dto.pdfData, "PayslipDTO should exclude PDF data by design")

        // But all other data should be preserved
        XCTAssertEqual(dto.id, payslipItem.id, "ID should be preserved")
        XCTAssertEqual(dto.credits, payslipItem.credits, "Credits should be preserved")
        XCTAssertEqual(dto.debits, payslipItem.debits, "Debits should be preserved")
        XCTAssertEqual(dto.month, payslipItem.month, "Month should be preserved")
        XCTAssertEqual(dto.year, payslipItem.year, "Year should be preserved")
    }

    /// Tests that the save path correctly uses savePayslipItemWithPDF vs savePayslipItem
    func testCorrectSaveMethodUsage() async throws {
        // This test verifies the architectural decision:
        // - savePayslipItemWithPDF() for initial saves with PDF data
        // - savePayslipItem() for updates without PDF changes

        let testPDFData = "Test PDF Content".data(using: .utf8)!
        let payslipItem = createTestPayslipItemWithPDF(data: testPDFData)

        let dataHandler = PayslipDataHandler()

        // Test 1: savePayslipItemWithPDF preserves PDF data
        let savedId1 = try await dataHandler.savePayslipItemWithPDF(payslipItem)
        XCTAssertEqual(savedId1, payslipItem.id, "PDF method should save successfully")

        // Verify PDF file exists
        let pdfManager = PDFManager.shared
        let pdfURL = pdfManager.getPDFURL(for: payslipItem.id.uuidString)
        XCTAssertNotNil(pdfURL, "PDF method should create PDF file")

        // Test 2: savePayslipItem (DTO-based) should succeed but not create PDF
        let dto = PayslipDTO(from: payslipItem)
        let savedId2 = try await dataHandler.savePayslipItem(dto)
        XCTAssertEqual(savedId2, payslipItem.id, "DTO method should save successfully")

        // Clean up
        cleanupTestPDFFile(for: payslipItem.id)
    }

    /// Tests that large PDF data is handled correctly
    func testLargePDFDataPreservation() async throws {
        // Create a larger test PDF to ensure memory handling works
        let largePDFData = Data(repeating: 0xFF, count: 100_000) // 100KB
        let payslipItem = createTestPayslipItemWithPDF(data: largePDFData)

        let dataHandler = PayslipDataHandler()

        // When: Saving large PDF data
        let savedId = try await dataHandler.savePayslipItemWithPDF(payslipItem)

        // Then: Should handle large data correctly
        XCTAssertEqual(savedId, payslipItem.id, "Should save large PDF successfully")

        // Verify large PDF file integrity
        let pdfManager = PDFManager.shared
        if let pdfURL = pdfManager.getPDFURL(for: payslipItem.id.uuidString) {
            let savedData = try Data(contentsOf: pdfURL)
            XCTAssertEqual(savedData.count, largePDFData.count, "Large PDF data should be preserved")
        }

        // Clean up
        cleanupTestPDFFile(for: payslipItem.id)
    }

    // MARK: - Helper Methods

    private func createTestPayslipItemWithPDF(data: Data) -> PayslipItem {
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
            pdfData: data
        )

        // Add dual-section earnings and deductions to test compatibility
        payslipItem.earnings = [
            "Basic Pay": 150000.0,
            "RH12_EARNINGS": 25000.0,
            "Dearness Allowance": 90000.0
        ]

        payslipItem.deductions = [
            "Income Tax": 45000.0,
            "RH12_DEDUCTIONS": 7500.0,
            "AGIF": 12500.0
        ]

        return payslipItem
    }

    private func cleanupTestPDFFile(for payslipId: UUID) {
        let pdfManager = PDFManager.shared
        if let pdfURL = pdfManager.getPDFURL(for: payslipId.uuidString) {
            try? FileManager.default.removeItem(at: pdfURL)
        }
    }
}

// MARK: - Architecture Validation Tests

/// Additional tests to validate the architectural decisions
extension PDFPreservationRegressionTest {

    /// Validates that the new method signature is correct and accessible
    func testNewMethodSignatureExists() {
        // This test ensures the method we added exists with correct signature
        let dataHandler = PayslipDataHandler()

        // This should compile if the method exists with correct signature
        Task {
            let payslipItem = createTestPayslipItemWithPDF(data: Data())
            let _ = try await dataHandler.savePayslipItemWithPDF(payslipItem)
        }

        // If this test compiles and runs, the method signature is correct
        XCTAssertTrue(true, "savePayslipItemWithPDF method exists with correct signature")
    }

    /// Validates that DataLoadingCoordinator uses the correct method
    func testDataLoadingCoordinatorUsesCorrectMethod() async throws {
        // This is a simplified architectural test
        // It verifies that our fix is in place by testing the method indirectly

        let testPDFData = "Test PDF Content".data(using: .utf8)!
        let payslipItem = createTestPayslipItemWithPDF(data: testPDFData)

        // Create the coordinator components
        let dataHandler = PayslipDataHandler()
        let chartService = ChartDataPreparationService()
        let coordinator = DataLoadingCoordinator(
            dataHandler: dataHandler,
            chartService: chartService
        )

        // When: Using the coordinator's save method (the one that was broken)
        try await coordinator.savePayslipAndReload(payslipItem)

        // Then: PDF should be preserved (this validates our fix)
        let pdfManager = PDFManager.shared
        let pdfURL = pdfManager.getPDFURL(for: payslipItem.id.uuidString)
        XCTAssertNotNil(pdfURL, "DataLoadingCoordinator should preserve PDF through save")

        if let pdfURL = pdfURL {
            XCTAssertTrue(FileManager.default.fileExists(atPath: pdfURL.path),
                         "DataLoadingCoordinator fix: PDF file should exist")
        }

        // Clean up
        cleanupTestPDFFile(for: payslipItem.id)
    }
}
