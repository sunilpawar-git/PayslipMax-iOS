import Foundation
import SwiftData
import PDFKit
#if canImport(UIKit)
import UIKit
#endif
import SwiftUI
@testable import PayslipMax

// MARK: - Mock Payslip Format Detection Service
class MockPayslipFormatDetectionService: PayslipFormatDetectionServiceProtocol {
    var mockFormat: PayslipFormat = .standard
    
    // Track method calls for verification in tests
    var detectFormatFromDataCallCount = 0
    var detectFormatFromTextCallCount = 0
    
    func detectFormat(_ data: Data) async -> PayslipFormat {
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