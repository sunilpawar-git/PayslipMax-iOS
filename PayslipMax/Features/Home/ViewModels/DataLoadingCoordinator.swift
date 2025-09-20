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

    /// The service for chart data preparation
    private let chartService: ChartDataPreparationService

    /// Completion handlers for loading results
    private var onLoadingSuccess: (() -> Void)?
    private var onLoadingFailure: ((Error) -> Void)?

    // MARK: - Initialization

    init(
        dataHandler: PayslipDataHandler,
        chartService: ChartDataPreparationService
    ) {
        self.dataHandler = dataHandler
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

    /// Loads the recent payslips
    func loadRecentPayslips() async {
        // Use global loading system
        GlobalLoadingManager.shared.startLoading(
            operationId: "home_recent_payslips",
            message: "Loading recent payslips..."
        )

        do {
            // Get payslips from the data handler
            let payslips = try await dataHandler.loadRecentPayslips()

            // Sort and filter
            let sortedPayslips = payslips.sorted { $0.timestamp > $1.timestamp }
            let recentOnes = Array(sortedPayslips.prefix(5))

            // Update chart data using the chart service
            let chartData = await chartService.prepareChartDataInBackground(from: sortedPayslips)

            // Update UI
            await MainActor.run {
                self.recentPayslips = recentOnes
                self.payslipData = chartData
            }

            onLoadingSuccess?()
        } catch {
            await MainActor.run {
                onLoadingFailure?(error)
            }
        }

        // Stop loading operation
        GlobalLoadingManager.shared.stopLoading(operationId: "home_recent_payslips")
    }

    /// Loads recent payslips with animation
    func loadRecentPayslipsWithAnimation() async {
        // Use global loading system
        GlobalLoadingManager.shared.startLoading(
            operationId: "home_data_load",
            message: "Loading data..."
        )

        do {
            // Get payslips from the data handler
            let payslips = try await dataHandler.loadRecentPayslips()

            // Sort and filter
            let sortedPayslips = payslips.sorted { $0.timestamp > $1.timestamp }
            let recentOnes = Array(sortedPayslips.prefix(5))

            // Update chart data using the chart service
            let chartData = await chartService.prepareChartDataInBackground(from: sortedPayslips)

            // Update UI with animation
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.recentPayslips = recentOnes
                    self.payslipData = chartData
                }
            }

            onLoadingSuccess?()
        } catch {
            print("DataLoadingCoordinator: Error loading payslips: \(error.localizedDescription)")
            onLoadingFailure?(error)
        }

        // Stop loading operation
        GlobalLoadingManager.shared.stopLoading(operationId: "home_data_load")
    }

    /// Saves a payslip item and reloads data
    /// - Parameter payslipItem: The payslip item to save
    func savePayslipAndReload(_ payslipItem: PayslipItem) async throws {
        let payslipDTO = PayslipDTO(from: payslipItem)
        _ = try await dataHandler.savePayslipItem(payslipDTO)
        await loadRecentPayslipsWithAnimation()
    }

    /// Refreshes all data (standard refresh)
    func refreshData() async {
        await loadRecentPayslipsWithAnimation()
    }

    /// Performs a forced refresh (clears data first)
    func forcedRefresh() async {
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
