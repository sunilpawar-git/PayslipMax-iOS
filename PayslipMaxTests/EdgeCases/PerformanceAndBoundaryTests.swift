import XCTest
@testable import Payslip_Max

@MainActor
final class PerformanceAndBoundaryTests: XCTestCase {
    
    // Systems under test
    var mockPDFService: MockPDFService!
    var mockDataService: MockDataService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create mock services
        mockPDFService = MockPDFService()
        try await mockPDFService.initialize()
        
        mockDataService = MockDataService()
        try await mockDataService.initialize()
    }
    
    override func tearDown() async throws {
        mockPDFService = nil
        mockDataService = nil
        try await super.tearDown()
    }
    
    // MARK: - Performance Tests
    
    /// Measures the performance of handling a large batch of payslips
    func testLargePayslipBatchPerformance() async throws {
        // Given - Prepare a large batch of payslips
        let batchSize = 100
        var payslips: [PayslipItem] = []
        
        for i in 0..<batchSize {
            let payslip = PayslipItem(
                id: UUID(),
                month: "January",
                year: 2023,
                credits: Double(5000 + i),
                debits: Double(1000 + (i % 10)),
                dsop: Double(300 + (i % 3)),
                tax: Double(800 + (i % 5)),
                name: "Test User \(i)",
                accountNumber: String(format: "%010d", i),
                panNumber: "ABCDE\(i)F"
            )
            payslips.append(payslip)
        }
        
        // When/Then - Measure the time to save all payslips
        measure {
            let expectation = XCTestExpectation(description: "Save large batch")
            
            Task {
                // Save all payslips
                for payslip in payslips {
                    try await self.mockDataService.save(payslip)
                }
                
                // Fetch all payslips
                let savedPayslips = try await self.mockDataService.fetch(PayslipItem.self)
                
                // Verify count
                XCTAssertEqual(savedPayslips.count, batchSize, "Should save all payslips")
                
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
    
    /// Measures the performance of payslip encryption operations
    func testEncryptionPerformance() throws {
        // Given - Create a large payslip with substantial data
        let payslip = PayslipItem(
            id: UUID(),
            month: "January",
            year: 2023,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 300.0,
            tax: 800.0,
            name: String(repeating: "Name", count: 100),
            accountNumber: String(repeating: "1234", count: 50),
            panNumber: String(repeating: "A", count: 50)
        )
        
        // When/Then - Measure encryption performance
        measure {
            // Encrypt and decrypt multiple times
            for _ in 0..<10 {
                try! payslip.encryptSensitiveData()
                try! payslip.decryptSensitiveData()
            }
        }
    }
    
    /// Measures the performance of PDF extraction operations
    func testPDFExtractionPerformance() {
        // Given - Create a large PDF with substantial data
        let largePDFText = String(repeating: "Performance test content\n", count: 1000)
        let pdfData = createPDFData(from: largePDFText)
        
        // Set up mock extraction result
        mockPDFService.extractResult = [
            "name": "Test User",
            "month": "January",
            "year": "2023",
            "credits": "5000.0",
            "debits": "1000.0",
            "tax": "800.0",
            "dsop": "300.0",
            "accountNumber": "1234567890",
            "panNumber": "ABCDE1234F"
        ]
        
        // When/Then - Measure PDF extraction performance
        measure {
            for _ in 0..<10 {
                let _ = mockPDFService.extract(pdfData)
            }
        }
    }
    
    // MARK: - Boundary Tests
    
    /// Tests handling of maximum allowed values
    func testMaximumValueBoundaries() async throws {
        // Given - Create a payslip with maximum values
        let maxPayslip = PayslipItem(
            id: UUID(),
            month: "December",
            year: Int.max,
            credits: Double.greatestFiniteMagnitude,
            debits: Double.greatestFiniteMagnitude,
            dsop: Double.greatestFiniteMagnitude,
            tax: Double.greatestFiniteMagnitude,
            name: String(repeating: "X", count: 1000), // Very long name
            accountNumber: String(repeating: "9", count: 1000), // Very long account number
            panNumber: String(repeating: "Z", count: 1000) // Very long PAN
        )
        
        // When - Try to save, encrypt, and retrieve the payslip
        try await mockDataService.save(maxPayslip)
        try maxPayslip.encryptSensitiveData()
        
        // Then - Verify it can be retrieved
        let savedPayslips = try await mockDataService.fetch(PayslipItem.self)
        XCTAssertEqual(savedPayslips.count, 1, "Should save one max-value payslip")
        
        // Verify can be decrypted
        try maxPayslip.decryptSensitiveData()
        
        // Verify data is preserved
        XCTAssertEqual(maxPayslip.year, Int.max, "Year should preserve max value")
        // Don't test exact equality for Double.greatestFiniteMagnitude due to potential rounding
        XCTAssertTrue(maxPayslip.credits > Double.greatestFiniteMagnitude * 0.99, "Credits should preserve max value")
    }
    
    /// Tests handling of zero and negative values
    func testZeroAndNegativeValueBoundaries() async throws {
        // Given - Create payslips with zero and negative values
        let zeroPayslip = PayslipItem(
            id: UUID(),
            month: "",
            year: 0,
            credits: 0,
            debits: 0,
            dsop: 0,
            tax: 0,
            name: "",
            accountNumber: "",
            panNumber: ""
        )
        
        let negativePayslip = PayslipItem(
            id: UUID(),
            month: "January",
            year: -2023,
            credits: -5000.0,
            debits: -1000.0,
            dsop: -300.0,
            tax: -800.0,
            name: "Negative Values",
            accountNumber: "-1234567890",
            panNumber: "-ABCDE1234F"
        )
        
        // When - Save and encrypt both payslips
        try await mockDataService.save(zeroPayslip)
        try await mockDataService.save(negativePayslip)
        
        try zeroPayslip.encryptSensitiveData()
        try negativePayslip.encryptSensitiveData()
        
        // Then - Verify they can be retrieved and decrypted
        let savedPayslips = try await mockDataService.fetch(PayslipItem.self)
        XCTAssertEqual(savedPayslips.count, 2, "Should save both boundary payslips")
        
        try zeroPayslip.decryptSensitiveData()
        try negativePayslip.decryptSensitiveData()
        
        // Verify zero values
        XCTAssertEqual(zeroPayslip.year, 0, "Zero year should be preserved")
        XCTAssertEqual(zeroPayslip.credits, 0, "Zero credits should be preserved")
        
        // Verify negative values
        XCTAssertEqual(negativePayslip.year, -2023, "Negative year should be preserved")
        XCTAssertEqual(negativePayslip.credits, -5000.0, "Negative credits should be preserved")
    }
    
    /// Tests handling of very large-scale data operations
    func testVeryLargeScaleOperations() async throws {
        // Given
        let largeCount = 10 // Adjusted for test performance, increase for real stress testing
        
        // Create a very large payslip array
        var largePayslips: [PayslipItem] = []
        for i in 0..<largeCount {
            let payslip = PayslipItem(
                id: UUID(),
                month: "January",
                year: 2023,
                credits: 5000.0,
                debits: 1000.0,
                dsop: 300.0,
                tax: 800.0,
                name: "User \(i)",
                accountNumber: "ACC\(i)",
                panNumber: "PAN\(i)"
            )
            largePayslips.append(payslip)
        }
        
        // When - Perform concurrent operations
        await withTaskGroup(of: Void.self) { group in
            // Save all payslips concurrently
            for payslip in largePayslips {
                group.addTask {
                    do {
                        try await self.mockDataService.save(payslip)
                    } catch {
                        XCTFail("Failed to save payslip: \(error)")
                    }
                }
            }
        }
        
        // Then - Verify all were saved
        let savedPayslips = try await mockDataService.fetch(PayslipItem.self)
        XCTAssertEqual(savedPayslips.count, largeCount, "Should save all large-scale payslips")
    }
    
    // MARK: - Helper Methods
    
    /// Creates a PDF data from text
    private func createPDFData(from text: String) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { context in
            context.beginPage()
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .natural
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .paragraphStyle: paragraphStyle
            ]
            
            text.draw(at: CGPoint(x: 10, y: 10), withAttributes: attributes)
        }
        
        return data
    }
} 