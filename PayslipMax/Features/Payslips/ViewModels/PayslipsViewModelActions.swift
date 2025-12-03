import SwiftUI
import SwiftData
import Foundation

// MARK: - PayslipsViewModel Actions Extension
extension PayslipsViewModel {

    // MARK: - Public Action Methods

    /// Loads payslips using smart caching (via PayslipCacheManager)
    func loadPayslips() async {
        // Use global loading system
        GlobalLoadingManager.shared.startLoading(
            operationId: "payslips_load",
            message: "Loading payslips..."
        )

        do {
            // Get payslips from cache manager (smart caching)
            let loadedPayslipItems = try await PayslipCacheManager.shared.loadPayslipsIfNeeded()

            await MainActor.run {
                // Store the loaded payslips (filtering/sorting is handled in computed properties)
                self.payslips = loadedPayslipItems
                self.updateGroupedData() // Update grouped data after loading
                print("PayslipsViewModel: Loaded \(loadedPayslipItems.count) payslips and applied sorting with order: \(self.sortOrder)")
            }
        } catch {
            await MainActor.run {
                self.error = AppError.from(error)
                print("PayslipsViewModel: Error loading payslips: \(error.localizedDescription)")
            }
        }

        // Stop loading operation
        GlobalLoadingManager.shared.stopLoading(operationId: "payslips_load")
    }

    /// Deletes a payslip from the specified context.
    ///
    /// - Parameters:
    ///   - payslip: The payslip to delete.
    ///   - context: The model context to delete from.
    func deletePayslip(_ payslip: AnyPayslip, from context: ModelContext) {
        Task {
            do {
                // Fetch the actual PayslipItem from the context using the ID
                let payslipId = payslip.id
                let descriptor = FetchDescriptor<PayslipItem>(
                    predicate: #Predicate<PayslipItem> { $0.id == payslipId }
                )

                guard let concretePayslip = try context.fetch(descriptor).first else {
                    await MainActor.run {
                        self.error = AppError.operationFailed("Payslip not found")
                    }
                    return
                }

                // Now delete the concrete PayslipItem
                context.delete(concretePayslip)

                // Save the context immediately
                try context.save()
                print("Successfully deleted from UI context")

                // Immediately remove from the local array on main thread for UI update
                await MainActor.run {
                    if let index = self.payslips.firstIndex(where: { $0.id == payslip.id }) {
                        self.payslips.remove(at: index)
                        print("Removed payslip from UI array, new count: \(self.payslips.count)")
                    } else {
                        print("Warning: Could not find payslip with ID \(payslip.id) in local array")
                    }
                }

                // Force a full deletion through the repository to ensure all contexts are updated
                _ = try await self.repository.deletePayslip(withId: payslipId)
                print("Successfully deleted from data service")

                // Invalidate cache to ensure fresh data
                PayslipCacheManager.shared.invalidateCache()

                // Flush all pending changes in the current context
                context.processPendingChanges()

                // Notify other components about the deletion
                PayslipEvents.notifyPayslipDeleted(id: payslip.id)

                // Force reload all payslips after a short delay to ensure consistency
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                await loadPayslips()

            } catch {
                print("Error deleting payslip: \(error)")

                // Enhanced error handling for dual-section payslip deletion
                await MainActor.run {
                    // Check if this is a dual-section data issue
                    if let appError = error as? AppError {
                        switch appError {
                        case .invalidPDFFormat:
                            // Special handling for PDF format errors during deletion
                            self.error = AppError.operationFailed("Unable to delete payslip due to PDF format issue. Please try again.")
                        case .dataExtractionFailed:
                            // Handle data extraction failures
                            self.error = AppError.operationFailed("Unable to delete payslip due to data processing issue. Please try again.")
                        default:
                            self.error = AppError.deleteFailed("Failed to delete payslip: \(appError.userMessage)")
                        }
                    } else {
                        self.error = AppError.deleteFailed("Failed to delete payslip: \(error.localizedDescription)")
                    }

                    // Force reload to ensure UI consistency after failed deletion
                    Task {
                        await self.loadPayslips()
                    }
                }
            }
        }
    }

    /// Deletes payslips at the specified indices from an array.
    ///
    /// - Parameters:
    ///   - indexSet: The indices of the payslips to delete.
    ///   - payslips: The array of payslips.
    ///   - context: The model context to delete from.
    func deletePayslips(at indexSet: IndexSet, from payslips: [AnyPayslip], context: ModelContext) {
        for index in indexSet {
            if index < payslips.count {
                deletePayslip(payslips[index], from: context)
            }
        }
    }

    /// Filters and sorts payslips based on the search text and sort order.
    ///
    /// - Parameters:
    ///   - payslips: The payslips to filter and sort.
    ///   - searchText: The text to search for. If nil, the view model's searchText is used.
    /// - Returns: The filtered and sorted payslips.
    func filterPayslips(_ payslips: [AnyPayslip], searchText: String? = nil) -> [AnyPayslip] {
        let searchQuery = searchText ?? self.searchText
        let filtered = filteringService.filter(payslips, searchText: searchQuery)
        return sortingService.sort(filtered, by: sortOrder)
    }

    /// Shares a payslip.
    ///
    /// - Parameter payslip: The payslip to share.
    func sharePayslip(_ payslip: AnyPayslip) {
        Task {
            // Create share text directly from the protocol (works with both PayslipItem and PayslipDTO)
            let shareText = """
            Payslip - \(payslip.month) \(payslip.year)

            Net Remittance: ₹\(String(format: "%.2f", payslip.credits - payslip.debits))
            Total Credits: ₹\(String(format: "%.2f", payslip.credits))
            Total Debits: ₹\(String(format: "%.2f", payslip.debits))
            """

            // Set the share text and show the share sheet
            await MainActor.run {
                self.shareText = shareText
                self.showShareSheet = true
            }
        }
    }

    /// Clears the payslips array
    func clearPayslips() {
        self.payslips = []
    }

    /// Clears all filters.
    func clearAllFilters() {
        searchText = ""
    }

    /// Clears the current error
    func clearError() {
        self.error = nil
    }
}
