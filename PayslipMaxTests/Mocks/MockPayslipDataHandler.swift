import Foundation
@testable import PayslipMax

// MARK: - Mock SendablePayslipRepository

/// Mock implementation of SendablePayslipRepository for testing
final class MockSendablePayslipRepository: @unchecked Sendable, SendablePayslipRepository {
    var payslips: [PayslipDTO] = []
    var shouldThrowError = false
    var errorToThrow: Error = AppError.message("Test error")

    func fetchAllPayslips() async throws -> [PayslipDTO] {
        if shouldThrowError {
            throw errorToThrow
        }
        return payslips
    }

    func fetchPayslips(fromDate: Date, toDate: Date) async throws -> [PayslipDTO] {
        if shouldThrowError {
            throw errorToThrow
        }
        return payslips.filter { $0.timestamp >= fromDate && $0.timestamp <= toDate }
    }

    func fetchPayslip(byId id: UUID) async throws -> PayslipDTO? {
        if shouldThrowError {
            throw errorToThrow
        }
        return payslips.first { $0.id == id }
    }

    func savePayslip(_ dto: PayslipDTO) async throws -> UUID {
        if shouldThrowError {
            throw errorToThrow
        }
        payslips.append(dto)
        return dto.id
    }

    func updatePayslip(withId id: UUID, from dto: PayslipDTO) async throws -> Bool {
        if shouldThrowError {
            throw errorToThrow
        }
        if let index = payslips.firstIndex(where: { $0.id == id }) {
            payslips[index] = dto
            return true
        }
        return false
    }

    func deletePayslip(withId id: UUID) async throws -> Bool {
        if shouldThrowError {
            throw errorToThrow
        }
        if let index = payslips.firstIndex(where: { $0.id == id }) {
            payslips.remove(at: index)
            return true
        }
        return false
    }

    func countPayslips() async throws -> Int {
        if shouldThrowError {
            throw errorToThrow
        }
        return payslips.count
    }
}

// MARK: - Mock Payslip Data Handler

/// Mock implementation of PayslipDataHandler for testing purposes.
/// Provides configurable behavior for data handling operations.
class MockPayslipDataHandler: PayslipDataHandler {
    var loadRecentPayslipsCalled = false
    var savePayslipItemCalled = false
    var createPayslipFromManualEntryCalled = false

    var mockRecentPayslips: [PayslipItem] = []
    var mockCreatedPayslipItem: PayslipDTO = PayslipDTO(from: TestDataGenerator.samplePayslipItem())
    var shouldThrowError = false
    var errorToThrow: Error = AppError.message("Test error")

    /// Initializes the mock with a mock repository and data service for testing
    init() {
        let mockRepository = MockSendablePayslipRepository()
        let mockDataService = MockDataService()
        super.init(repository: mockRepository, dataService: mockDataService)
    }

    /// Loads recent payslips with configurable behavior
    override func loadRecentPayslips() async throws -> [PayslipItem] {
        loadRecentPayslipsCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        return mockRecentPayslips
    }

    /// Saves a payslip item with configurable error behavior
    override func savePayslipItem(_ dto: PayslipDTO) async throws -> UUID {
        savePayslipItemCalled = true
        if shouldThrowError {
            throw errorToThrow
        }
        return dto.id
    }

    /// Creates a payslip item from manual entry data
    override func createPayslipItemFromManualData(_ manualData: PayslipManualEntryData) -> PayslipDTO {
        createPayslipFromManualEntryCalled = true
        return mockCreatedPayslipItem
    }

    /// Resets all tracking flags and mock data to default values
    func reset() {
        loadRecentPayslipsCalled = false
        savePayslipItemCalled = false
        createPayslipFromManualEntryCalled = false
        mockRecentPayslips = []
        mockCreatedPayslipItem = PayslipDTO(from: TestDataGenerator.samplePayslipItem())
        shouldThrowError = false
        errorToThrow = AppError.message("Test error")
    }
}
