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
        let previous = MockPayslip(
            id: UUID(),
            timestamp: Date(),
            month: "January",
            year: 2025,
            credits: 100000,
            debits: 25000,
            dsop: 8000,
            tax: 15000,
            earnings: [:],
            deductions: [:],
            name: "Current",
            accountNumber: "111",
            panNumber: "AAAAB1234C",
            pdfData: nil,
            isSample: false,
            source: "Test",
            status: "Active"
        )

        let current = MockPayslip(
            id: UUID(),
            timestamp: Date(),
            month: "February",
            year: 2025,
            credits: 110000,
            debits: 25000,
            dsop: 8000,
            tax: 15000,
            earnings: [:],
            deductions: [:],
            name: "Current",
            accountNumber: "111",
            panNumber: "AAAAB1234C",
            pdfData: nil,
            isSample: false,
            source: "Test",
            status: "Active"
        )

        let next = MockPayslip(
            id: UUID(),
            timestamp: Date(),
            month: "March",
            year: 2025,
            credits: 115000,
            debits: 25000,
            dsop: 8000,
            tax: 15000,
            earnings: [:],
            deductions: [:],
            name: "Next",
            accountNumber: "222",
            panNumber: "BBBCC1234D",
            pdfData: nil,
            isSample: false,
            source: "Test",
            status: "Active"
        )

        let viewModel = PayslipDetailViewModel(
            payslip: current,
            comparisonService: PayslipComparisonService(),
            comparisonCacheManager: cacheManager,
            xRaySettings: xRaySettings,
            allPayslips: [previous, current, next]
        )

        // Seed stale cache entries
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
        isXRayEnabled.toggle()
    }
}

