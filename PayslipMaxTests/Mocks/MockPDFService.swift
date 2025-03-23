import Foundation
@testable import Payslip_Max

class MockPDFService: PDFServiceProtocol {
    var shouldFail = false
    var initializeCallCount = 0
    var extractCallCount = 0
    var unlockCallCount = 0
    var processCallCount = 0
    var mockPDFData = Data()
    var unlockResult = Data()
    var extractResult: [String: String] = [:]
    var isInitialized: Bool = false
    
    // Additional property for test compatibility
    var mockPayslipData: PayslipItem?
    
    func initialize() async throws {
        initializeCallCount += 1
        if shouldFail {
            throw NSError(domain: "MockPDFService", code: 100, userInfo: [NSLocalizedDescriptionKey: "Mock initialization failed"])
        }
        isInitialized = true
    }
    
    func process(_ url: URL) async throws -> Data {
        processCallCount += 1
        if shouldFail {
            throw NSError(domain: "MockPDFService", code: 103, userInfo: [NSLocalizedDescriptionKey: "Mock process failed"])
        }
        return mockPDFData
    }
    
    func extract(_ data: Data) -> [String : String] {
        extractCallCount += 1
        if shouldFail {
            return [:]
        }
        return extractResult
    }
    
    func unlockPDF(data: Data, password: String) async throws -> Data {
        unlockCallCount += 1
        if shouldFail {
            throw NSError(domain: "MockPDFService", code: 102, userInfo: [NSLocalizedDescriptionKey: "Mock unlock failed"])
        }
        return unlockResult
    }
    
    // Legacy methods kept for backward compatibility
    func extractText(from pdfData: Data) async throws -> [String : String] {
        return extract(pdfData)
    }
    
    func unlockPDF(_ pdfData: Data, password: String) throws -> Data {
        // This is a synchronous wrapper around the async method
        // For tests, just return the result directly
        unlockCallCount += 1
        if shouldFail {
            throw NSError(domain: "MockPDFService", code: 102, userInfo: [NSLocalizedDescriptionKey: "Mock unlock failed"])
        }
        return unlockResult
    }
    
    func readPDFFromURL(_ url: URL) throws -> Data {
        // For tests, just return the mockPDFData directly
        if shouldFail {
            throw NSError(domain: "MockPDFService", code: 103, userInfo: [NSLocalizedDescriptionKey: "Mock read failed"])
        }
        return mockPDFData
    }
} 