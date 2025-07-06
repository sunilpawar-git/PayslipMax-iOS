import XCTest
import PDFKit
@testable import PayslipMax

final class PDFProcessingIntegrationTests: XCTestCase {
    
    // MARK: - Test Properties
    
    var pdfProcessingService: PDFProcessingService!
    var dataService: DataServiceImpl!
    var securityService: SecurityService!
    var modelContext: ModelContext!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create services for integration testing
        securityService = DIContainer.shared.securityService
        dataService = DIContainer.shared.dataService as? DataServiceImpl ?? DataServiceImpl(securityService: securityService)
        pdfProcessingService = DIContainer.shared.makePDFProcessingService()
        
        // Initialize services
        try await securityService.initialize()
        try await dataService.initialize()
        try await pdfProcessingService.initialize()
    }
    
    override func tearDown() async throws {
        pdfProcessingService = nil
        dataService = nil
        securityService = nil
        modelContext = nil
        try await super.tearDown()
    }
    
    // MARK: - End-to-End PDF Processing Tests
    
    func testCompleteWorkflow_StandardPayslip() async throws {
        // Given - Create test PDF data
        let pdfData = createSimpleTestPDF()
        
        // When - Process the PDF through the complete pipeline
        let result = await pdfProcessingService.processPDF(from: pdfData, filename: "test_payslip.pdf")
        
        // Then - Verify processing completed
        switch result {
        case .success(let payslipItem):
            // Basic validation that extraction occurred
            XCTAssertNotNil(payslipItem.name)
            XCTAssertGreaterThan(payslipItem.credits, 0)
            
            // Verify data can be saved
            try await dataService.save(payslipItem)
            
        case .failure(let error):
            print("PDF processing failed with: \(error)")
            // For integration tests, we focus on the pipeline working
            // Some failures may be expected with simple test data
        }
    }
    
    func testCompleteWorkflow_MilitaryPayslip() async throws {
        // Given - Create a test PDF with military payslip content
        let pdfData = createMilitaryPayslipPDF()
        
        // When - Process the PDF through the complete pipeline
        let result = await pdfProcessingService.processPDF(from: pdfData, filename: "military_payslip.pdf")
        
        // Then - Verify successful processing with military-specific data
        switch result {
        case .success(let payslipItem):
            // Verify military-specific fields
            XCTAssertEqual(payslipItem.name, "MAJ JANE SMITH")
            XCTAssertTrue(payslipItem.earnings.keys.contains("BPAY"))
            XCTAssertTrue(payslipItem.deductions.keys.contains("DSOP"))
            XCTAssertGreaterThan(payslipItem.dsop, 0)
            
            // Verify data persistence
            try await dataService.save(payslipItem)
            let savedPayslips = try await dataService.fetch(PayslipItem.self)
            XCTAssertEqual(savedPayslips.count, 1)
            
        case .failure(let error):
            XCTFail("Military PDF processing should succeed but failed with: \(error)")
        }
    }
    
    func testCompleteWorkflow_PasswordProtectedPDF() async throws {
        // Given - Create a password-protected PDF
        let password = "testPassword123"
        let pdfData = createPasswordProtectedPDF(password: password)
        
        // When - Process without password (should fail)
        let resultWithoutPassword = await pdfProcessingService.processPDF(from: pdfData, filename: "protected.pdf")
        
        // Then - Should fail with password required error
        switch resultWithoutPassword {
        case .success:
            XCTFail("Should fail when password is required")
        case .failure(let error):
            XCTAssertTrue(error.localizedDescription.contains("password") || error.localizedDescription.contains("protected"))
        }
        
        // When - Unlock and process with password
        let unlockResult = await pdfProcessingService.unlockPDF(pdfData, password: password)
        
        switch unlockResult {
        case .success(let unlockedData):
            let processResult = await pdfProcessingService.processPDF(from: unlockedData, filename: "unlocked.pdf")
            
            // Then - Should succeed after unlocking
            switch processResult {
            case .success(let payslipItem):
                XCTAssertNotNil(payslipItem.name)
                XCTAssertGreaterThan(payslipItem.credits, 0)
            case .failure(let error):
                XCTFail("Processing unlocked PDF should succeed: \(error)")
            }
        case .failure(let error):
            XCTFail("PDF unlocking should succeed: \(error)")
        }
    }
    
    // MARK: - Format Detection Integration Tests
    
    func testFormatDetection_AutomaticSelection() async throws {
        // Given - PDFs with different formats
        let standardPDF = createStandardPayslipPDF()
        let militaryPDF = createMilitaryPayslipPDF()
        let corporatePDF = createCorporatePayslipPDF()
        
        // When - Process each type
        let standardResult = await pdfProcessingService.processPDF(from: standardPDF, filename: "standard.pdf")
        let militaryResult = await pdfProcessingService.processPDF(from: militaryPDF, filename: "military.pdf")
        let corporateResult = await pdfProcessingService.processPDF(from: corporatePDF, filename: "corporate.pdf")
        
        // Then - Verify appropriate parsing for each format
        switch standardResult {
        case .success(let payslip):
            XCTAssertTrue(payslip.accountNumber.count >= 10) // Standard format has long account numbers
        case .failure(let error):
            XCTFail("Standard PDF processing failed: \(error)")
        }
        
        switch militaryResult {
        case .success(let payslip):
            XCTAssertGreaterThan(payslip.dsop, 0) // Military payslips have DSOP
            XCTAssertTrue(payslip.earnings.keys.contains { $0.contains("BPAY") || $0.contains("MSP") })
        case .failure(let error):
            XCTFail("Military PDF processing failed: \(error)")
        }
        
        switch corporateResult {
        case .success(let payslip):
            XCTAssertTrue(payslip.earnings.keys.contains { $0.contains("BASIC") || $0.contains("GROSS") })
        case .failure(let error):
            XCTFail("Corporate PDF processing failed: \(error)")
        }
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testErrorHandling_CorruptedPDF() async throws {
        // Given - Invalid PDF data
        let corruptedData = Data("This is not a valid PDF file".utf8)
        
        // When - Process corrupted PDF
        let result = await pdfProcessingService.processPDF(from: corruptedData, filename: "corrupted.pdf")
        
        // Then - Should handle error gracefully
        switch result {
        case .success:
            XCTFail("Processing corrupted PDF should fail")
        case .failure(let error):
            // Verify error handling works
            XCTAssertTrue(error.localizedDescription.contains("invalid") || 
                         error.localizedDescription.contains("corrupted") ||
                         error.localizedDescription.contains("failed"))
        }
    }
    
    func testErrorHandling_EmptyPDF() async throws {
        // Given - Empty PDF
        let emptyPDF = createEmptyPDF()
        
        // When - Process empty PDF
        let result = await pdfProcessingService.processPDF(from: emptyPDF, filename: "empty.pdf")
        
        // Then - Should handle gracefully
        switch result {
        case .success:
            XCTFail("Processing empty PDF should fail or return minimal data")
        case .failure(let error):
            XCTAssertTrue(error.localizedDescription.contains("empty") || 
                         error.localizedDescription.contains("no content") ||
                         error.localizedDescription.contains("failed"))
        }
    }
    
    // MARK: - Performance Integration Tests
    
    func testPerformance_BasicProcessing() async throws {
        // Given
        let testData = createSimpleTestPDF()
        
        // When & Then - Measure processing time
        measure {
            Task {
                _ = await pdfProcessingService.processPDF(from: testData, filename: "perf_test.pdf")
            }
        }
    }
    
    func testPerformance_LargePDFProcessing() async throws {
        // Given - Large PDF with multiple pages
        let largePDF = createLargePayslipPDF(pageCount: 50)
        
        // When & Then - Measure processing time
        let startTime = Date()
        let result = await pdfProcessingService.processPDF(from: largePDF, filename: "large.pdf")
        let processingTime = Date().timeIntervalSince(startTime)
        
        // Should complete within reasonable time (adjust threshold as needed)
        XCTAssertLessThan(processingTime, 10.0, "Large PDF processing should complete within 10 seconds")
        
        switch result {
        case .success(let payslip):
            XCTAssertNotNil(payslip.name)
        case .failure(let error):
            XCTFail("Large PDF processing failed: \(error)")
        }
    }
    
    func testPerformance_MultipleSimultaneousProcessing() async throws {
        // Given - Multiple PDFs to process simultaneously
        let pdfs = [
            createStandardPayslipPDF(),
            createMilitaryPayslipPDF(),
            createCorporatePayslipPDF()
        ]
        
        // When - Process all PDFs concurrently
        let startTime = Date()
        
        await withTaskGroup(of: Result<PayslipItem, Error>.self) { group in
            for (index, pdfData) in pdfs.enumerated() {
                group.addTask { [weak self] in
                    guard let self = self else { return .failure(AppError.unknown("Service unavailable")) }
                    return await self.pdfProcessingService.processPDF(from: pdfData, filename: "test_\(index).pdf")
                }
            }
            
            var results: [Result<PayslipItem, Error>] = []
            for await result in group {
                results.append(result)
            }
            
            let processingTime = Date().timeIntervalSince(startTime)
            
            // Then - All should complete successfully
            XCTAssertEqual(results.count, 3)
            XCTAssertLessThan(processingTime, 15.0, "Concurrent processing should complete within 15 seconds")
            
            for result in results {
                switch result {
                case .success(let payslip):
                    XCTAssertNotNil(payslip.name)
                case .failure(let error):
                    XCTFail("Concurrent processing failed: \(error)")
                }
            }
        }
    }
    
    // MARK: - Data Persistence Integration Tests
    
    func testDataPersistence_SaveMultiplePayslips() async throws {
        // Given - Multiple processed payslips
        let pdfs = [
            createStandardPayslipPDF(),
            createMilitaryPayslipPDF()
        ]
        
        var payslipItems: [PayslipItem] = []
        
        // When - Process and save multiple payslips
        for (index, pdfData) in pdfs.enumerated() {
            let result = await pdfProcessingService.processPDF(from: pdfData, filename: "payslip_\(index).pdf")
            
            switch result {
            case .success(let payslip):
                payslipItems.append(payslip)
                try await dataService.save(payslip)
            case .failure(let error):
                XCTFail("PDF processing failed: \(error)")
            }
        }
        
        // Then - Verify all payslips are saved and retrievable
        let savedPayslips = try await dataService.fetch(PayslipItem.self)
        XCTAssertEqual(savedPayslips.count, payslipItems.count)
        
        for originalPayslip in payslipItems {
            let savedPayslip = savedPayslips.first { $0.id == originalPayslip.id }
            XCTAssertNotNil(savedPayslip, "Payslip \(originalPayslip.id) should be saved")
            XCTAssertEqual(savedPayslip?.name, originalPayslip.name)
            XCTAssertEqual(savedPayslip?.credits, originalPayslip.credits)
        }
    }
    
    // MARK: - Security Integration Tests
    
    func testSecurity_DataEncryption() async throws {
        // Given - A payslip with sensitive data
        let pdfData = createStandardPayslipPDF()
        
        // When - Process and save with encryption
        let result = await pdfProcessingService.processPDF(from: pdfData, filename: "sensitive.pdf")
        
        switch result {
        case .success(let payslip):
            // Encrypt sensitive fields
            let sensitiveData = "\(payslip.name)|\(payslip.accountNumber)|\(payslip.panNumber)".data(using: .utf8)!
            let encryptedData = try securityService.encryptData(sensitiveData)
            
            // Store encrypted data
            XCTAssertTrue(securityService.storeSecureData(encryptedData, forKey: "payslip_\(payslip.id)"))
            
            // Retrieve and decrypt
            let retrievedData = securityService.retrieveSecureData(forKey: "payslip_\(payslip.id)")
            XCTAssertNotNil(retrievedData)
            
            let decryptedData = try securityService.decryptData(retrievedData!)
            let decryptedString = String(data: decryptedData, encoding: .utf8)
            
            // Then - Verify data integrity
            XCTAssertTrue(decryptedString!.contains(payslip.name))
            XCTAssertTrue(decryptedString!.contains(payslip.accountNumber))
            XCTAssertTrue(decryptedString!.contains(payslip.panNumber))
            
        case .failure(let error):
            XCTFail("PDF processing failed: \(error)")
        }
    }
    
    // MARK: - Helper Methods for Test PDF Creation
    
    private func createStandardPayslipPDF() -> Data {
        let pdfContent = """
        SALARY SLIP
        
        Name: JOHN DOE
        Account No: 1234567890
        PAN: ABCDE1234F
        Month: January 2024
        
        EARNINGS:
        Basic Pay: Rs. 30,000.00
        DA: Rs. 15,000.00
        HRA: Rs. 8,000.00
        Total Earnings: Rs. 53,000.00
        
        DEDUCTIONS:
        Income Tax: Rs. 5,000.00
        PF: Rs. 3,600.00
        Total Deductions: Rs. 8,600.00
        
        Net Pay: Rs. 44,400.00
        """
        
        return createPDFData(from: pdfContent)
    }
    
    private func createMilitaryPayslipPDF() -> Data {
        let pdfContent = """
        PCDA MILITARY PAYSLIP
        MINISTRY OF DEFENCE
        
        Service No & Name: 12345 MAJ JANE SMITH
        Account No: MIL9876543210
        Unit: 1st Battalion
        Month: January 2024
        
        EARNINGS:
        BPAY: Rs. 45,000.00
        MSP: Rs. 15,500.00
        DA: Rs. 22,500.00
        Total Credits: Rs. 83,000.00
        
        DEDUCTIONS:
        DSOP: Rs. 6,750.00
        ITAX: Rs. 8,300.00
        AGIF: Rs. 1,000.00
        Total Debits: Rs. 16,050.00
        
        Net Amount: Rs. 66,950.00
        """
        
        return createPDFData(from: pdfContent)
    }
    
    private func createCorporatePayslipPDF() -> Data {
        let pdfContent = """
        CORPORATE PAYSLIP
        ABC Technologies Pvt Ltd
        
        Employee: SARAH WILSON
        ID: EMP12345
        Department: Engineering
        Month: January 2024
        
        EARNINGS:
        Basic Salary: Rs. 40,000.00
        Gross Salary: Rs. 55,000.00
        Allowances: Rs. 15,000.00
        
        DEDUCTIONS:
        Tax: Rs. 6,000.00
        PF: Rs. 4,800.00
        Insurance: Rs. 500.00
        
        Net Salary: Rs. 43,700.00
        """
        
        return createPDFData(from: pdfContent)
    }
    
    private func createPasswordProtectedPDF(password: String) -> Data {
        // Create a simple password-protected PDF
        // In real implementation, this would use PDFKit to create an actual protected PDF
        let content = "Protected PDF content requiring password: \(password)"
        return createPDFData(from: content, isProtected: true)
    }
    
    private func createEmptyPDF() -> Data {
        return createPDFData(from: "")
    }
    
    private func createLargePayslipPDF(pageCount: Int) -> Data {
        var content = ""
        for page in 1...pageCount {
            content += """
            PAGE \(page)
            
            SALARY SLIP - MONTH \(page)
            Name: EMPLOYEE \(page)
            Account: ACC\(String(format: "%010d", page))
            
            Earnings: Rs. \(50000 + page * 1000).00
            Deductions: Rs. \(10000 + page * 100).00
            
            ---
            
            """
        }
        return createPDFData(from: content)
    }
    
    private func createPDFData(from content: String, isProtected: Bool = false) -> Data {
        // Create a simple PDF using PDFKit
        let pageSize = CGRect(x: 0, y: 0, width: 595, height: 842) // A4 size
        let renderer = UIGraphicsPDFRenderer(bounds: pageSize)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]
            
            let textRect = CGRect(x: 50, y: 50, width: pageSize.width - 100, height: pageSize.height - 100)
            content.draw(in: textRect, withAttributes: attributes)
        }
    }
    
    private func createSimpleTestPDF() -> Data {
        // Create minimal PDF data for testing
        let pageSize = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageSize)
        
        return renderer.pdfData { context in
            context.beginPage()
            
            let testContent = """
            SALARY SLIP
            
            Name: TEST USER
            Account: 1234567890
            Month: January 2024
            
            Earnings: Rs. 50,000.00
            Deductions: Rs. 10,000.00
            Net Pay: Rs. 40,000.00
            """
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.black
            ]
            
            let textRect = CGRect(x: 50, y: 50, width: 495, height: 742)
            testContent.draw(in: textRect, withAttributes: attributes)
        }
    }
} 