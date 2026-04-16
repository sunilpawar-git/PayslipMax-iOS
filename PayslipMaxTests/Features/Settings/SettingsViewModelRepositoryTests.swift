import XCTest
import SwiftData
@testable import PayslipMax

/// Tests that SettingsViewModel.loadPayslips uses the injected repository
/// rather than pulling one from DIContainer inside the action method.
@MainActor
final class SettingsViewModelRepositoryTests: BaseTestCase {

    private var mockDataService: MockDataService!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockDataService = MockDataService()
    }

    override func tearDownWithError() throws {
        mockDataService = nil
        try super.tearDownWithError()
    }

    func test_loadPayslips_usesInjectedRepository() async throws {
        // Given: A mock repository with known payslips
        let mockRepo = MockSendablePayslipRepository()
        let dto = PayslipDTO(
            id: UUID(), timestamp: Date(),
            month: "March", year: 2025,
            credits: 60_000, debits: 12_000,
            dsop: 3_000, tax: 9_000,
            earnings: [:], deductions: [:],
            name: "Injected User",
            accountNumber: "ACC001", panNumber: "PAN001"
        )
        mockRepo.payslips = [dto]

        let vm = SettingsViewModel(dataService: mockDataService, repository: mockRepo)
        let modelContainer = try ModelContainer(for: PayslipItem.self)
        let context = modelContainer.mainContext

        // When
        vm.loadPayslips(context: context)
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then: payslips come from the injected repo, not DIContainer
        XCTAssertEqual(vm.payslips.count, 1)
        XCTAssertEqual(vm.payslips.first?.name, "Injected User")
    }

    func test_loadPayslips_withRepositoryError_setsEmptyPayslips() async throws {
        // Given: A mock repository that throws
        let mockRepo = MockSendablePayslipRepository()
        mockRepo.shouldThrowError = true

        let vm = SettingsViewModel(dataService: mockDataService, repository: mockRepo)
        let modelContainer = try ModelContainer(for: PayslipItem.self)
        let context = modelContainer.mainContext

        // When
        vm.loadPayslips(context: context)
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then: payslips are empty and loading is stopped
        XCTAssertTrue(vm.payslips.isEmpty)
        XCTAssertFalse(vm.isLoading)
    }
}
