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
            // Use cache manager to load (will use cache if valid)
            await loadPayslips()
        }
    }

    /// Handler for forced refresh notifications - more aggressive than regular refresh
    @objc private func handlePayslipsForcedRefresh() {
        Task {
            // Invalidate cache first
            await MainActor.run {
                cacheManager.invalidateCache()
            }

            // Reset our payslips array
            await MainActor.run {
                self.clearPayslips()
                self.isLoading = true
            }

            // Small delay to ensure cache invalidation completes
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 second

            // Now load the payslips with fresh fetch (cache is invalidated, so will fetch fresh)
            await loadPayslips()

            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}
