import Foundation
@testable import PayslipMax

/// Shared mock repository for testing payslip-related operations
/// Implements SendablePayslipRepository protocol for use in backup, quiz, and other tests
@MainActor
final class MockPayslipRepository: SendablePayslipRepository {

    // MARK: - Mock Data

    /// Payslips to return from fetch operations
    var mockPayslips: [PayslipDTO] = []

    /// Payslips that were saved during test execution
    var savedPayslips: [PayslipDTO] = []

    /// Payslips that were deleted during test execution
    var deletedPayslipIds: [UUID] = []

    // MARK: - Call Tracking

    var fetchAllPayslipsCalled = false
    var fetchPayslipByIdCalled = false
    var savePayslipCalled = false
    var updatePayslipCalled = false
    var deletePayslipCalled = false

    // MARK: - Error Simulation

    /// Set to true to simulate errors in operations
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "MockError", code: 1, userInfo: nil)

    // MARK: - SendablePayslipRepository Implementation

    func fetchAllPayslips() async throws -> [PayslipDTO] {
        fetchAllPayslipsCalled = true
        if shouldThrowError { throw errorToThrow }
        return mockPayslips
    }

    func fetchPayslips(fromDate: Date, toDate: Date) async throws -> [PayslipDTO] {
        if shouldThrowError { throw errorToThrow }
        return mockPayslips.filter { $0.timestamp >= fromDate && $0.timestamp <= toDate }
    }

    func fetchPayslip(byId id: UUID) async throws -> PayslipDTO? {
        fetchPayslipByIdCalled = true
        if shouldThrowError { throw errorToThrow }
        return mockPayslips.first { $0.id == id }
    }

    func savePayslip(_ dto: PayslipDTO) async throws -> UUID {
        savePayslipCalled = true
        if shouldThrowError { throw errorToThrow }
        savedPayslips.append(dto)
        return dto.id
    }

    func updatePayslip(withId id: UUID, from dto: PayslipDTO) async throws -> Bool {
        updatePayslipCalled = true
        if shouldThrowError { throw errorToThrow }
        if let index = savedPayslips.firstIndex(where: { $0.id == id }) {
            savedPayslips[index] = dto
            return true
        }
        return false
    }

    func deletePayslip(withId id: UUID) async throws -> Bool {
        deletePayslipCalled = true
        if shouldThrowError { throw errorToThrow }
        deletedPayslipIds.append(id)
        savedPayslips.removeAll { $0.id == id }
        return true
    }

    func countPayslips() async throws -> Int {
        if shouldThrowError { throw errorToThrow }
        return mockPayslips.count
    }

    // MARK: - Test Helpers

    /// Reset all tracking state
    func reset() {
        mockPayslips = []
        savedPayslips = []
        deletedPayslipIds = []
        fetchAllPayslipsCalled = false
        fetchPayslipByIdCalled = false
        savePayslipCalled = false
        updatePayslipCalled = false
        deletePayslipCalled = false
        shouldThrowError = false
    }
}
