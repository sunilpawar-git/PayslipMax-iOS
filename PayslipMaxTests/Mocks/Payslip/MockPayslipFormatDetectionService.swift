import Foundation
import PDFKit
@testable import PayslipMax

/// Mock implementation of PayslipFormatDetectionServiceProtocol for testing
class MockPayslipFormatDetectionService: PayslipFormatDetectionServiceProtocol {
    var mockFormat: PayslipFormat = .standard
    
    // Track method calls for verification in tests
    var detectFormatFromDataCallCount = 0
    var detectFormatFromTextCallCount = 0
    
    func detectFormat(_ data: Data) -> PayslipFormat {
        detectFormatFromDataCallCount += 1
        return mockFormat
    }
    
    func detectFormat(fromText text: String) -> PayslipFormat {
        detectFormatFromTextCallCount += 1
        return mockFormat
    }
    
    func reset() {
        mockFormat = .standard
        detectFormatFromDataCallCount = 0
        detectFormatFromTextCallCount = 0
    }
} 