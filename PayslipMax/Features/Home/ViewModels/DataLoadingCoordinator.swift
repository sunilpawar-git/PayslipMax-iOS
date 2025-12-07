import Foundation
import SwiftUI
import Combine

/// Coordinates all data loading operations for HomeViewModel
/// Follows single responsibility principle by handling only data loading and chart preparation
@MainActor
class DataLoadingCoordinator: ObservableObject {
    // MARK: - Published Properties

    /// Whether data loading is in progress
    @Published var isLoading = false

    /// The recent payslips to display
    @Published var recentPayslips: [AnyPayslip] = []

    /// The data for the charts
    @Published var payslipData: [PayslipChartData] = []

    // MARK: - Private Properties

    /// The handler for payslip data operations
    private let dataHandler: PayslipDataHandler

    /// The cache manager for payslip caching
    private let cacheManager: PayslipCacheManager

    /// The service for chart data preparation
    private let chartService: ChartDataPreparationService

    /// Completion handlers for loading results
    private var onLoadingSuccess: (() -> Void)?
    private var onLoadingFailure: ((Error) -> Void)?

    // MARK: - Initialization

    init(
        dataHandler: PayslipDataHandler,
        cacheManager: PayslipCacheManager,
        chartService: ChartDataPreparationService
    ) {
        self.dataHandler = dataHandler
        self.cacheManager = cacheManager
        self.chartService = chartService
    }

    // MARK: - Public Methods

    /// Sets completion handlers for loading results
    func setCompletionHandlers(
        onSuccess: @escaping () -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        self.onLoadingSuccess = onSuccess
        self.onLoadingFailure = onFailure
    }

    /// Loads recent payslips with optional animation using smart caching
    /// - Parameter animated: Whether to animate the UI updates (default: false)
    func loadRecentPayslips(animated: Bool = false) async {
        let operationId = animated ? "home_data_load" : "home_recent_payslips"
        let message = animated ? "Loading data..." : "Loading recent payslips..."

        // Use global loading system (skip during tests to avoid QoS noise)
        if !ProcessInfo.isRunningInTestEnvironment {
            GlobalLoadingManager.shared.startLoading(
                operationId: operationId,
                message: message
            )
        }

        do {
            // Get payslips from cache manager (smart caching)
            let payslips = try await cacheManager.loadPayslipsIfNeeded()

            // Sort and filter
            let sortedPayslips = payslips.sorted { $0.timestamp > $1.timestamp }
            let recentOnes = Array(sortedPayslips.prefix(5))

            // Update chart data using the chart service
            let chartData = await chartService.prepareChartDataInBackground(from: sortedPayslips)

            // Update UI (with optional animation)
            await MainActor.run {
                if animated {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.recentPayslips = recentOnes
                        self.payslipData = chartData
                    }
                } else {
                    self.recentPayslips = recentOnes
                    self.payslipData = chartData
                }
            }

            onLoadingSuccess?()
        } catch {
            if animated {
                print("DataLoadingCoordinator: Error loading payslips: \(error.localizedDescription)")
            }
            onLoadingFailure?(error)
        }

        // Stop loading operation
        if !ProcessInfo.isRunningInTestEnvironment {
            GlobalLoadingManager.shared.stopLoading(operationId: operationId)
        }
    }

    /// Loads recent payslips with animation using smart caching
    /// Deprecated: Use loadRecentPayslips(animated: true) instead
    func loadRecentPayslipsWithAnimation() async {
        await loadRecentPayslips(animated: true)
    }

    /// Saves a payslip item, invalidates cache, and reloads data
    /// - Parameter payslipItem: The payslip item to save
    func savePayslipAndReload(_ payslipItem: PayslipItem) async throws {
        // Use the method that preserves PDF data during initial save
        _ = try await dataHandler.savePayslipItemWithPDF(payslipItem)

        // Invalidate cache to ensure fresh data on next load
        cacheManager.invalidateCache()

        // Reload with fresh data
        await loadRecentPayslipsWithAnimation()
    }

    /// Refreshes all data (standard refresh)
    func refreshData() async {
        await loadRecentPayslipsWithAnimation()
    }

    /// Performs a forced refresh (clears cache and data first)
    func forcedRefresh() async {
        // Invalidate cache for forced refresh
        cacheManager.invalidateCache()

        // Clear current data first
        await MainActor.run {
            self.recentPayslips = []
            self.payslipData = []
        }

        // Small delay to ensure UI updates properly
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        // Reload all data from scratch
        await loadRecentPayslipsWithAnimation()
    }

    /// Removes a payslip from the current list if present
    /// - Parameter payslipId: The ID of the payslip to remove
    func removePayslipFromList(_ payslipId: UUID) async {
        // Remove the deleted payslip from recentPayslips if present
        if let index = recentPayslips.firstIndex(where: { $0.id == payslipId }) {
            print("DataLoadingCoordinator: Removing deleted payslip from recent payslips")
            _ = await MainActor.run {
                self.recentPayslips.remove(at: index)
            }
        }

        // Reload all data to keep everything in sync
        await loadRecentPayslipsWithAnimation()
    }

    /// Cancels all loading operations
    func cancelLoading() {
        // Stop all home-related loading operations
        GlobalLoadingManager.shared.stopLoading(operationId: "home_recent_payslips")
        GlobalLoadingManager.shared.stopLoading(operationId: "home_data_load")

        // Reset local loading state
        isLoading = false
    }
}
