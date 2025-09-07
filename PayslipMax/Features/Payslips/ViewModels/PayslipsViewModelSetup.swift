import Foundation
import SwiftData

// MARK: - PayslipsViewModel Setup Extension
extension PayslipsViewModel {

    // MARK: - Setup Methods

    /// Sets up notification handlers for payslip events
    func setupNotificationHandlers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePayslipsRefresh),
            name: .payslipsRefresh,
            object: nil
        )

        // Add observer for forced refresh notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePayslipsForcedRefresh),
            name: .payslipsForcedRefresh,
            object: nil
        )
    }

    /// Handler for payslips refresh notification
    @objc private func handlePayslipsRefresh() {
        Task {
            await loadPayslips()
        }
    }

    /// Handler for forced refresh notifications - more aggressive than regular refresh
    @objc private func handlePayslipsForcedRefresh() {
        Task {
            // Reset our payslips array first
            await MainActor.run {
                self.clearPayslips()
                self.isLoading = true
            }

            // Small delay to ensure UI updates and contexts reset
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

            // Reset the data service to force a clean state
            if let dataServiceImpl = dataService as? DataServiceImpl {
                // Process pending changes to flush any operations
                dataServiceImpl.processPendingChanges()

                // Additional call to ensure data is refreshed
                dataServiceImpl.processPendingChanges()
            }

            // Reinitialize the data service to force a clean fetch
            try? await dataService.initialize()

            // Additional delay to ensure context is fully reset
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

            // Now load the payslips with fresh fetch
            let fetchedPayslips = try? await dataService.fetchRefreshed(PayslipItem.self)

            await MainActor.run {
                if let payslips = fetchedPayslips {
                    self.payslips = payslips
                    print("PayslipsViewModel: Force refreshed with \(payslips.count) payslips")
                }
                self.isLoading = false
            }
        }
    }
}
