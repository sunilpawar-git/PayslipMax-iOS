import SwiftUI
import SwiftData
import Foundation

// MARK: - PayslipsViewModel Actions Extension
extension PayslipsViewModel {

    // MARK: - Public Action Methods

    /// Loads payslips from the data service.
    func loadPayslips() async {
        // Use global loading system
        GlobalLoadingManager.shared.startLoading(
            operationId: "payslips_load",
            message: "Loading payslips..."
        )

        do {
            let loadedPayslips = try await dataService.fetch(PayslipItem.self)

            await MainActor.run {
                // Store the loaded payslips (filtering/sorting is handled in computed properties)
                self.payslips = loadedPayslips
                self.updateGroupedData() // Update grouped data after loading
                print("PayslipsViewModel: Loaded \(loadedPayslips.count) payslips and applied sorting with order: \(self.sortOrder)")
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
        // Since we're using a protocol, we need to handle the concrete type
        if let concretePayslip = payslip as? PayslipItem {
            Task {
                do {
                    // First delete from the context (UI update)
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

                    // Force a full deletion through the data service to ensure all contexts are updated
                    try await self.dataService.delete(concretePayslip)
                    print("Successfully deleted from data service")

                    // Flush all pending changes in the current context
                    context.processPendingChanges()

                    // Notify other components about the deletion
                    PayslipEvents.notifyPayslipDeleted(id: payslip.id)

                    // Force reload all payslips after a short delay to ensure consistency
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    await loadPayslips()

                } catch {
                    print("Error deleting payslip: \(error)")
                    await MainActor.run {
                        self.error = AppError.deleteFailed("Failed to delete payslip: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            // Log the error for debugging purposes
            print("Warning: Deletion of non-PayslipItem types is not implemented")

            // Notify the user about the error
            DispatchQueue.main.async {
                self.error = AppError.operationFailed("Cannot delete this type of payslip")
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
            do {
                // Try to get a PayslipItem from AnyPayslip
                guard let payslipItem = payslip as? PayslipItem else {
                    await MainActor.run {
                        self.error = AppError.message("Cannot share this type of payslip")
                    }
                    return
                }

                // Try to decrypt the payslip if needed
                try await payslipItem.decryptSensitiveData()

                // Set the share text and show the share sheet
                await MainActor.run {
                    shareText = payslipItem.formattedDescription()
                    showShareSheet = true
                }
            } catch {
                await MainActor.run {
                    self.error = AppError.from(error)
                }
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
