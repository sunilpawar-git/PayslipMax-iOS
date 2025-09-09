import SwiftUI
import Combine

/// ViewModel for CategorizedPayItemsView
@MainActor
final class CategorizedPayItemsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var categorizedEarnings: [String: [PayItem]] = [:]
    @Published private(set) var categorizedDeductions: [String: [PayItem]] = [:]
    @Published private(set) var totalEarnings: Double = 0
    @Published private(set) var totalDeductions: Double = 0
    @Published private(set) var isLoading = false

    // MARK: - Private Properties

    private let categorizationService: PayItemCategorizationServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        earnings: [String: Double],
        deductions: [String: Double],
        categorizationService: PayItemCategorizationServiceProtocol
    ) {
        self.categorizationService = categorizationService

        Task {
            await updatePayItems(earnings: earnings, deductions: deductions)
        }
    }

    // MARK: - Public Methods

    /// Updates the pay items and recalculates categories
    func updatePayItems(earnings: [String: Double], deductions: [String: Double]) async {
        isLoading = true
        defer { isLoading = false }

        // Calculate totals
        totalEarnings = earnings.values.reduce(0, +)
        totalDeductions = deductions.values.reduce(0, +)

        // Categorize items asynchronously
        async let earningsTask = categorizationService.categorizePayItems(earnings)
        async let deductionsTask = categorizationService.categorizePayItems(deductions)

        let (earningsResult, deductionsResult) = await (earningsTask, deductionsTask)

        categorizedEarnings = earningsResult
        categorizedDeductions = deductionsResult
    }

    /// Net pay calculation
    var netPay: Double {
        totalEarnings - totalDeductions
    }
}
