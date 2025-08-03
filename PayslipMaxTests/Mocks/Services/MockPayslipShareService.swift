import Foundation
import SwiftUI
@testable import PayslipMax

/// Mock implementation of PayslipShareService for testing
@MainActor
class MockPayslipShareService: PayslipShareService {
    
    // MARK: - Mock State
    var mockShareItems: [Any] = []
    var shouldThrowError = false
    var mockError = AppError.message("Mock Share Service Error")
    
    // Track method calls
    var getShareItemsCallCount = 0
    
    override init(pdfService: PayslipPDFService? = nil,
                  formatterService: PayslipFormatterService? = nil) {
        // Initialize with mock dependencies
        super.init(
            pdfService: pdfService ?? MockPayslipPDFService(),
            formatterService: formatterService ?? MockPayslipFormatterService()
        )
        setupDefaultMockData()
    }
    
    private func setupDefaultMockData() {
        mockShareItems = ["Mock Share Text", MockShareItemProvider()]
    }
    
    // Test helper method to access the mocked data  
    func getMockShareItems(for payslip: AnyPayslip, payslipData: Models.PayslipData) async -> [Any] {
        getShareItemsCallCount += 1
        return mockShareItems
    }
    
    // MARK: - Test Helper Methods
    
    func reset() {
        getShareItemsCallCount = 0
        shouldThrowError = false
        mockError = AppError.message("Mock Share Service Error")
        setupDefaultMockData()
    }
    
    func setMockShareItems(_ items: [Any]) {
        mockShareItems = items
    }
    
    func setShouldThrowError(_ shouldThrow: Bool, error: AppError? = nil) {
        shouldThrowError = shouldThrow
        if let error = error {
            mockError = error
        }
    }
}

// MARK: - Mock Share Item Provider

class MockShareItemProvider: NSObject {
    let content = "Mock Share Content"
    let title = "Mock Share Title"
}