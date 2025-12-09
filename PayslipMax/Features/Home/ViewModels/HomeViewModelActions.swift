import Foundation
import SwiftUI
import PDFKit

/// Action handlers for HomeViewModel
/// Contains all public methods that handle user interactions and business logic
extension HomeViewModel {

    // MARK: - Data Loading Actions

    /// Loads the recent payslips
    func loadRecentPayslips() {
        Task(priority: .userInitiated) {
            await dataCoordinator.loadRecentPayslips()
        }
    }

    /// Loads recent payslips with animation
    func loadRecentPayslipsWithAnimation() async {
        await dataCoordinator.loadRecentPayslipsWithAnimation()
    }

    // MARK: - PDF Processing Actions

    /// Processes a payslip PDF from a URL
    /// - Parameter url: The URL of the PDF to process
    func processPayslipPDF(from url: URL) async {
        await pdfCoordinator.processPayslipPDF(from: url)
    }

    /// Processes PDF data after it has been unlocked or loaded directly
    /// - Parameters:
    ///   - data: The PDF data to process
    ///   - url: The original URL of the PDF file (optional)
    func processPDFData(_ data: Data, from url: URL? = nil) async {
        await pdfCoordinator.processPDFData(data, from: url)
    }

    /// Handles an unlocked PDF
    /// - Parameters:
    ///   - data: The unlocked PDF data
    ///   - originalPassword: The original password used to unlock the PDF
    func handleUnlockedPDF(data: Data, originalPassword: String) async {
        await pdfCoordinator.handleUnlockedPDF(data: data, originalPassword: originalPassword)
    }

    // MARK: - Manual Entry Actions

    /// Processes a manual entry
    /// - Parameter payslipData: The payslip data to process
    func processManualEntry(_ payslipData: PayslipManualEntryData) {
        Task {
            await manualEntryCoordinator.processManualEntry(payslipData)
        }
    }

    /// Shows the manual entry form
    func showManualEntry() {
        print("[HomeViewModel] showManualEntry called")

        // Add a small delay to ensure UI is ready and avoid conflicts with other sheets
        Task { @MainActor in
            // Small delay to ensure any other sheet dismissals are complete
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

            print("[HomeViewModel] About to call manualEntryCoordinator.showManualEntry()")
            manualEntryCoordinator.showManualEntry()
            print("[HomeViewModel] manualEntryCoordinator.showManualEntry() completed")
        }
    }

    /// Hides the manual entry form
    func hideManualEntry() {
        manualEntryCoordinator.hideManualEntry()
    }

    /// Processes a scanned payslip image
    /// - Parameter image: The scanned image
    func processScannedPayslip(from image: UIImage) {
        Task {
            await manualEntryCoordinator.processScannedPayslip(from: image)
        }
    }

    // MARK: - Control Actions

    /// Cancels loading
    func cancelLoading() {
        pdfCoordinator.cancelProcessing()
        dataCoordinator.cancelLoading()
        manualEntryCoordinator.cancelProcessing()
    }

    // MARK: - Error Handling Actions

    /// Handles an error by setting the appropriate error properties
    /// - Parameter error: The error to handle
    func handleError(_ error: Error) {
        errorHandler.handleError(error)
    }

    /// Clears the current error state
    func clearError() {
        errorHandler.clearError()
    }
}
