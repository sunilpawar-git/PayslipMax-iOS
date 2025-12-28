import Combine
import XCTest
@testable import PayslipMax

@MainActor
final class PayslipDetailViewModelXRayTests: XCTestCase {

    private var xRaySettings: MockXRaySettingsService!
    private var cacheManager: PayslipComparisonCacheManager!

    override func setUp() {
        super.setUp()
        xRaySettings = MockXRaySettingsService()
        cacheManager = PayslipComparisonCacheManager()
        cacheManager.clearCache()
        cacheManager.waitForPendingOperations()
    }

    override func tearDown() {
        cacheManager.clearCache()
        cacheManager.waitForPendingOperations()
        xRaySettings = nil
        cacheManager = nil
        super.tearDown()
    }

    func testUpdatePayslipData_InvalidatesAndRefreshesCache() {
        // Given
        let (previous, current, next) = createTestPayslips()
        let viewModel = createViewModel(current: current, allPayslips: [previous, current, next])
        seedStaleCache(previous: previous, current: current, next: next)

        // When
        viewModel.invalidateComparisons()
        cacheManager.waitForPendingOperations()
        viewModel.refreshComparisonsIfNeeded()
        cacheManager.waitForPendingOperations()

        // Then
        let currentCached = cacheManager.getComparison(for: current.id)
        XCTAssertEqual(currentCached?.netRemittanceChange, 10000)
        XCTAssertNil(cacheManager.getComparison(for: next.id))
    }

    // MARK: - Test Data Helpers

    private func createTestPayslips() -> (MockPayslip, MockPayslip, MockPayslip) {
        let previous = createMockPayslip(month: "January", credits: 100000, name: "Current", accountNumber: "111")
        let current = createMockPayslip(month: "February", credits: 110000, name: "Current", accountNumber: "111")
        let next = createMockPayslip(month: "March", credits: 115000, name: "Next", accountNumber: "222", panNumber: "BBBCC1234D")
        return (previous, current, next)
    }

    private func createMockPayslip(
        month: String,
        credits: Double,
        name: String,
        accountNumber: String,
        panNumber: String = "AAAAB1234C"
    ) -> MockPayslip {
        MockPayslip(
            id: UUID(),
            timestamp: Date(),
            month: month,
            year: 2025,
            credits: credits,
            debits: 25000,
            dsop: 8000,
            tax: 15000,
            earnings: [:],
            deductions: [:],
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber,
            pdfData: nil,
            isSample: false,
            source: "Test",
            status: "Active"
        )
    }

    private func createViewModel(current: MockPayslip, allPayslips: [MockPayslip]) -> PayslipDetailViewModel {
        PayslipDetailViewModel(
            payslip: current,
            comparisonService: PayslipComparisonService(),
            comparisonCacheManager: cacheManager,
            xRaySettings: xRaySettings,
            allPayslips: allPayslips
        )
    }

    private func seedStaleCache(previous: MockPayslip, current: MockPayslip, next: MockPayslip) {
        let staleCurrentComparison = PayslipComparison(
            currentPayslip: current,
            previousPayslip: previous,
            netRemittanceChange: 1,
            netRemittancePercentageChange: nil,
            earningsChanges: [:],
            deductionsChanges: [:]
        )

        let staleNextComparison = PayslipComparison(
            currentPayslip: next,
            previousPayslip: current,
            netRemittanceChange: 2,
            netRemittancePercentageChange: nil,
            earningsChanges: [:],
            deductionsChanges: [:]
        )

        cacheManager.setComparison(staleCurrentComparison, for: current.id)
        cacheManager.setComparison(staleNextComparison, for: next.id)
        cacheManager.waitForPendingOperations()
    }
}

// MARK: - Test Doubles

@MainActor
private final class MockXRaySettingsService: XRaySettingsServiceProtocol, ObservableObject {
    var isXRayEnabled: Bool {
        didSet { subject.send(isXRayEnabled) }
    }

    private let subject = PassthroughSubject<Bool, Never>()

    var xRayEnabledPublisher: AnyPublisher<Bool, Never> {
        subject.eraseToAnyPublisher()
    }

    init(enabled: Bool = true) {
        self.isXRayEnabled = enabled
    }

    func toggleXRay(onPaywallRequired: @escaping () -> Void) {
        if !isXRayEnabled {
            isXRayEnabled = true
        }
        subject.send(isXRayEnabled)
    }
}
