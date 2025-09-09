import Foundation
@testable import PayslipMax

// MARK: - Mock Payslip Data Handler

/// Mock implementation of PayslipDataHandler for testing purposes.
/// Provides configurable behavior for data handling operations.
class MockPayslipDataHandler: PayslipDataHandler {
    var loadRecentPayslipsCalled = false
    var savePayslipItemCalled = false
    var createPayslipFromManualEntryCalled = false

    var mockRecentPayslips: [AnyPayslip] = []
    var mockCreatedPayslipItem: PayslipItem = TestDataGenerator.samplePayslipItem()
    var shouldThrowError = false
    var errorToThrow: Error = AppError.message("Test error")

    /// Initializes the mock with a mock data service for testing
    init() {
        let mockDataService = MockDataService()
        super.init(dataService: mockDataService)
    }

    /// Loads recent payslips with configurable behavior
    func loadRecentPayslips() async throws -> [AnyPayslip] {
        loadRecentPayslipsCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        return mockRecentPayslips
    }

    /// Saves a payslip item with configurable error behavior
    override func savePayslipItem(_ item: PayslipItem) async throws {
        savePayslipItemCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
    }

    /// Creates a payslip item from manual entry data
    override func createPayslipItemFromManualData(_ manualData: PayslipManualEntryData) -> PayslipItem {
        createPayslipFromManualEntryCalled = true
        return mockCreatedPayslipItem
    }

    /// Resets all tracking flags and mock data to default values
    func reset() {
        loadRecentPayslipsCalled = false
        savePayslipItemCalled = false
        createPayslipFromManualEntryCalled = false
        mockRecentPayslips = []
        mockCreatedPayslipItem = TestDataGenerator.samplePayslipItem()
        shouldThrowError = false
        errorToThrow = AppError.message("Test error")
    }
}
