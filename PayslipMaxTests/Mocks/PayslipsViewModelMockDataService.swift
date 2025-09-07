import XCTest
@testable import PayslipMax

// MARK: - Mock Data Service for PayslipsViewModel

/// Mock data service specifically designed for PayslipsViewModel testing
/// Following SOLID principles with protocol-based design and dependency injection
@MainActor
final class PayslipsViewModelMockDataService: DataServiceProtocol {
    var payslips: [PayslipItem] = []
    var shouldFailFetch = false
    var shouldFailSave = false
    var shouldFailDelete = false
    var isInitialized = false

    func initialize() async throws {
        isInitialized = true
    }

    func fetch<T>(_ type: T.Type) async throws -> [T] where T : Identifiable {
        if shouldFailFetch {
            throw AppError.fetchFailed("Mock fetch error")
        }

        if type == PayslipItem.self {
            return payslips as! [T]
        }

        return []
    }

    func fetchRefreshed<T>(_ type: T.Type) async throws -> [T] where T : Identifiable {
        return try await fetch(type)
    }

    func save<T>(_ entity: T) async throws where T : Identifiable {
        if shouldFailSave {
            throw AppError.saveFailed("Mock save error")
        }

        if let payslip = entity as? PayslipItem {
            payslips.append(payslip)
        }
    }

    func saveBatch<T>(_ entities: [T]) async throws where T : Identifiable {
        for entity in entities {
            try await save(entity)
        }
    }

    func delete<T>(_ entity: T) async throws where T : Identifiable {
        if shouldFailDelete {
            throw AppError.deleteFailed("Mock delete error")
        }

        if let payslip = entity as? PayslipItem {
            payslips.removeAll { $0.id == payslip.id }
        }
    }

    func deleteBatch<T>(_ entities: [T]) async throws where T : Identifiable {
        for entity in entities {
            try await delete(entity)
        }
    }

    func clearAllData() async throws {
        payslips.removeAll()
    }
}
