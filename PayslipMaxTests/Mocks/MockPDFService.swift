import Foundation
@testable import Payslip_Max

// Instead of inheriting from PDFService, implement PDFServiceProtocol
class MockPDFService: PDFServiceProtocol {
    // Make all properties nonisolated
    nonisolated(unsafe) var shouldFail = false
    nonisolated(unsafe) var initializeCallCount = 0
    nonisolated(unsafe) var extractCallCount = 0
    nonisolated(unsafe) var unlockCallCount = 0
    nonisolated(unsafe) var processCallCount = 0
    nonisolated(unsafe) var mockPDFData = Data()
    nonisolated(unsafe) var unlockResult = Data()
    nonisolated(unsafe) var extractResult: [String: String] = [:]
    nonisolated(unsafe) var isInitialized: Bool = false
    nonisolated(unsafe) var fileType: PDFFileType = .standard
    
    // Additional property for test compatibility
    nonisolated(unsafe) var mockPayslipData: PayslipItem?
    
    // Required by PDFServiceProtocol
    nonisolated func initialize() async throws {
        initializeCallCount += 1
        isInitialized = true
    }
    
    // Required by PDFServiceProtocol
    nonisolated func extract(_ pdfData: Data) -> [String: String] {
        extractCallCount += 1
        
        if shouldFail {
            return ["error": "PDF Extraction Failed"]
        }
        
        return extractResult
    }
    
    // Required by PDFServiceProtocol
    nonisolated func unlockPDF(data: Data, password: String) async throws -> Data {
        unlockCallCount += 1
        
        if shouldFail {
            throw PDFServiceError.incorrectPassword
        }
        
        return unlockResult
    }
    
    // Required by PDFServiceProtocol
    nonisolated func process(_ url: URL) async throws -> Data {
        processCallCount += 1
        
        if shouldFail {
            throw PDFServiceError.unableToProcessPDF
        }
        
        return mockPDFData
    }
    
    // Legacy method for backward compatibility with existing tests
    nonisolated func readPDFFromURL(_ url: URL) async throws -> Data {
        mockPDFData
    }
    
    // Legacy method for backward compatibility with existing tests
    nonisolated func isPasswordProtected(_ pdfData: Data) -> Bool {
        // We can't actually check if the PDF is password protected here
        // Just return based on a flag in our mock
        return fileType == .standard && shouldFail // Use a combination of flags instead of .passwordProtected
    }
    
    // Legacy methods kept for backward compatibility
    nonisolated func extractText(from pdfData: Data) async throws -> [String : String] {
        return extract(pdfData)
    }
    
    nonisolated func unlockPDF(_ pdfData: Data, password: String) throws -> Data {
        // This is a synchronous wrapper around the async method
        // For tests, just return the result directly
        unlockCallCount += 1
        if shouldFail {
            throw PDFServiceError.incorrectPassword
        }
        return unlockResult
    }
    
    // Reset the mock to default state
    nonisolated func reset() {
        shouldFail = false
        fileType = .standard
        extractCallCount = 0
        initializeCallCount = 0
        unlockCallCount = 0
        processCallCount = 0
        mockPDFData = Data()
        unlockResult = Data()
        extractResult = [:]
        isInitialized = false
        mockPayslipData = nil
    }
} 