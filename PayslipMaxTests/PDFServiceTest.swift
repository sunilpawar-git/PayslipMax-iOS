import XCTest
@testable import PayslipMax

/// Test for PDFService basic operations
@MainActor
final class PDFServiceTest: XCTestCase {
    
    var pdfService: DefaultPDFService!
    
    override func setUp() {
        super.setUp()
        pdfService = DefaultPDFService()
    }
    
    override func tearDown() {
        pdfService = nil
        super.tearDown()
    }
    
    func testPDFServiceInitialization() {
        // Test initial state
        XCTAssertNotNil(pdfService)
        XCTAssertEqual(pdfService.fileType, .standard)
    }
    
    func testExtractFromInvalidData() {
        // Test with invalid PDF data
        let invalidData = "Not a PDF".data(using: .utf8)!
        
        let result = pdfService.extract(invalidData)
        
        // Should return empty dictionary for invalid data
        XCTAssertTrue(result.isEmpty)
    }
    
    func testExtractFromEmptyData() {
        // Test with empty data
        let emptyData = Data()
        
        let result = pdfService.extract(emptyData)
        
        // Should return empty dictionary for empty data
        XCTAssertTrue(result.isEmpty)
    }
    
    func testFileTypeProperty() {
        // Test file type getter
        let fileType = pdfService.fileType
        XCTAssertEqual(fileType, .standard)
        
        // Test file type setter
        pdfService.fileType = .military
        XCTAssertEqual(pdfService.fileType, .military)
        
        pdfService.fileType = .pcda
        XCTAssertEqual(pdfService.fileType, .pcda)
    }
    
    func testUnlockPDFWithEmptyData() async {
        // Test unlocking with empty data
        let emptyData = Data()
        let password = "test123"
        
        do {
            let _ = try await pdfService.unlockPDF(data: emptyData, password: password)
            XCTFail("Should have thrown an error for empty data")
        } catch PDFServiceError.unableToProcessPDF {
            XCTAssert(true, "Expected error for empty data")
        } catch PDFServiceError.invalidFormat {
            XCTAssert(true, "Expected error for empty data")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testUnlockPDFWithInvalidData() async {
        // Test unlocking with invalid PDF data
        let invalidData = "Not a PDF".data(using: .utf8)!
        let password = "test123"
        
        do {
            let _ = try await pdfService.unlockPDF(data: invalidData, password: password)
            XCTFail("Should have thrown an error for invalid data")
        } catch PDFServiceError.unableToProcessPDF {
            XCTAssert(true, "Expected error for invalid data")
        } catch PDFServiceError.invalidFormat {
            XCTAssert(true, "Expected error for invalid data")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testPDFServiceErrorEquality() {
        // Test error equality
        XCTAssertEqual(PDFServiceError.incorrectPassword, PDFServiceError.incorrectPassword)
        XCTAssertEqual(PDFServiceError.unableToProcessPDF, PDFServiceError.unableToProcessPDF)
        XCTAssertEqual(PDFServiceError.invalidFormat, PDFServiceError.invalidFormat)
        
        // Test error inequality
        XCTAssertNotEqual(PDFServiceError.incorrectPassword, PDFServiceError.unableToProcessPDF)
        XCTAssertNotEqual(PDFServiceError.invalidFormat, PDFServiceError.failedToExtractText)
    }
    
    func testPDFFileTypeEnumCases() {
        // Test all file type cases exist
        let standardType = PDFFileType.standard
        let militaryType = PDFFileType.military
        let pcdaType = PDFFileType.pcda
        
        XCTAssertNotNil(standardType)
        XCTAssertNotNil(militaryType)
        XCTAssertNotNil(pcdaType)
        
        // Test file type setting on service
        pdfService.fileType = standardType
        XCTAssertEqual(pdfService.fileType, .standard)
        
        pdfService.fileType = militaryType
        XCTAssertEqual(pdfService.fileType, .military)
        
        pdfService.fileType = pcdaType
        XCTAssertEqual(pdfService.fileType, .pcda)
    }
    
    func testExtractReturnsValidDictionary() {
        // Test that extract always returns a dictionary
        let validData = Data([0x25, 0x50, 0x44, 0x46]) // PDF header bytes
        
        let result = pdfService.extract(validData)
        
        // Should return a dictionary (might be empty for invalid/incomplete PDF)
        XCTAssertNotNil(result)
    }
    
    func testConcurrentOperations() async {
        // Test concurrent extract operations
        let testData1 = "Test data 1".data(using: .utf8)!
        let testData2 = "Test data 2".data(using: .utf8)!
        let testData3 = "Test data 3".data(using: .utf8)!
        
        await withTaskGroup(of: [String: String].self) { group in
            group.addTask { [weak self] in
                return await self?.pdfService.extract(testData1) ?? [:]
            }
            group.addTask { [weak self] in
                return await self?.pdfService.extract(testData2) ?? [:]
            }
            group.addTask { [weak self] in
                return await self?.pdfService.extract(testData3) ?? [:]
            }
            
            var results: [[String: String]] = []
            for await result in group {
                results.append(result)
            }
            
            // All operations should complete without crashes
            XCTAssertEqual(results.count, 3)
        }
    }
}