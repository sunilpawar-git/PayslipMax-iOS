import SwiftUI
import Foundation

/// Handles UI state management for PayslipDetailViewModel
/// Responsible for loading states, error handling, dialog management, and payslip data updates
@MainActor
class PayslipDetailStateManager: ObservableObject {

    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var error: AppError?
    @Published var payslipData: PayslipData
    @Published var showShareSheet = false
    @Published var showDiagnostics = false
    @Published var showOriginalPDF = false
    @Published var showPrintDialog = false
    @Published var unknownComponents: [String: (Double, String)] = [:]

    // MARK: - Private Properties
    private let payslip: AnyPayslip
    private let repository: SendablePayslipRepository

    // MARK: - Cache Properties
    private var shareItemsCache: [Any]?

    // MARK: - Initialization

    init(payslip: AnyPayslip, repository: SendablePayslipRepository? = nil) {
        self.payslip = payslip
        self.repository = repository ?? DIContainer.shared.makeSendablePayslipRepository()

        // Set the initial payslip data
        self.payslipData = PayslipData(from: payslip)
    }

    // MARK: - Public Methods

    /// Updates the payslip with corrected data.
    ///
    /// - Parameter correctedData: The corrected payslip data.
    func updatePayslipData(_ correctedData: PayslipData) {
        Task {
            do {
                guard let payslipItem = payslip as? PayslipItem else {
                    error = AppError.message("Cannot update payslip: Invalid payslip type")
                    return
                }

                // Set loading state
                isLoading = true
                defer { isLoading = false }

                // Update the payslip item with the corrected data
                payslipItem.name = correctedData.name
                payslipItem.accountNumber = correctedData.accountNumber
                payslipItem.panNumber = correctedData.panNumber
                payslipItem.credits = correctedData.totalCredits
                payslipItem.debits = correctedData.totalDebits
                payslipItem.dsop = correctedData.dsop
                payslipItem.tax = correctedData.incomeTax

                // Update earnings/deductions
                payslipItem.earnings = correctedData.allEarnings
                payslipItem.deductions = correctedData.allDeductions

                // Save changes using repository
                let payslipDTO = PayslipDTO(from: payslipItem)
                _ = try await repository.savePayslip(payslipDTO)

                // Update our local data
                self.payslipData = correctedData

                // Clear caches
                clearCaches()

                // Post notification about update
                NotificationCenter.default.post(name: AppNotification.payslipUpdated, object: nil)
            } catch {
                self.error = AppError.message("Failed to update payslip: \(error.localizedDescription)")
            }
        }
    }

    /// Called when a user categorizes an unknown component
    func userCategorizedComponent(code: String, asCategory: String) {
        if let (amount, _) = unknownComponents[code] {
            // Update the category in the unknown components dictionary
            unknownComponents[code] = (amount, asCategory)

            // Also update the appropriate earnings or deductions collection
            if asCategory == "earnings" {
                var updatedEarnings = payslipData.allEarnings
                updatedEarnings[code] = amount
                payslipData.allEarnings = updatedEarnings
            } else if asCategory == "deductions" {
                var updatedDeductions = payslipData.allDeductions
                updatedDeductions[code] = amount
                payslipData.allDeductions = updatedDeductions
            }
        }
    }

    /// Handles an error and updates the error state
    ///
    /// - Parameter error: The error to handle.
    func handleError(_ error: Error) {
        ErrorLogger.log(error)
        self.error = AppError.from(error)
    }

    /// Clears the current error state
    func clearError() {
        error = nil
    }

    /// Sets loading state
    /// - Parameter loading: Whether the view model is loading
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }

    /// Shows the share sheet
    func presentShareSheet() {
        showShareSheet = true
    }

    /// Hides the share sheet
    func dismissShareSheet() {
        showShareSheet = false
    }

    /// Shows the diagnostics view
    func presentDiagnostics() {
        showDiagnostics = true
    }

    /// Hides the diagnostics view
    func dismissDiagnostics() {
        showDiagnostics = false
    }

    /// Shows the original PDF view
    func presentOriginalPDF() {
        showOriginalPDF = true
    }

    /// Hides the original PDF view
    func dismissOriginalPDF() {
        showOriginalPDF = false
    }

    /// Shows the print dialog
    func presentPrintDialog() {
        showPrintDialog = true
    }

    /// Hides the print dialog
    func dismissPrintDialog() {
        showPrintDialog = false
    }

    /// Clears all caches (to be called when data is updated)
    func clearCaches() {
        shareItemsCache = nil
    }

    /// Caches share items for performance
    /// - Parameter items: The share items to cache
    func cacheShareItems(_ items: [Any]) {
        shareItemsCache = items
    }

    /// Gets cached share items if available
    /// - Returns: Cached share items or nil if not available
    func getCachedShareItems() -> [Any]? {
        return shareItemsCache
    }

    /// Enriches the payslip data with additional information from parsing
    func enrichPayslipData(with pdfData: [String: String]) {
        // Create temporary data model from the parsed PDF data for merging
        var tempData = PayslipData(from: PayslipItemFactory.createEmpty() as AnyPayslip)

        // Add data from PDF parsing
        for (key, value) in pdfData {
            // Example mapping logic:
            switch key.lowercased() {
            case "rank":
                tempData.rank = value
            case "name":
                tempData.name = value
            case "posting":
                tempData.postedTo = value
            // Add more mappings as needed
            default:
                break
            }
        }

        // Merge this data with our payslipData, but preserve core financial data
        mergeParsedData(tempData)
    }

    // MARK: - Private Methods

    /// Helper to merge parsed data while preserving core financial values
    private func mergeParsedData(_ parsedData: PayslipData) {
        // Personal details (can be overridden by PDF data if available)
        if !parsedData.name.isEmpty { payslipData.name = parsedData.name }
        if !parsedData.rank.isEmpty { payslipData.rank = parsedData.rank }
        if !parsedData.postedTo.isEmpty { payslipData.postedTo = parsedData.postedTo }

        // Don't override the core financial data from the original payslip
    }
}
