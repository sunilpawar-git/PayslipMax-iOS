import SwiftUI
import Foundation
import PDFKit

/// Handles user actions for PayslipDetailViewModel
/// Responsible for printing, saving changes, and other user-initiated actions
@MainActor
class PayslipDetailActionsHandler {

    // MARK: - Dependencies
    private let stateManager: PayslipDetailStateManager
    private let pdfHandler: PayslipDetailPDFHandler
    private var payslip: AnyPayslip

    // MARK: - Initialization

    init(stateManager: PayslipDetailStateManager,
         pdfHandler: PayslipDetailPDFHandler,
         payslip: AnyPayslip) {
        self.stateManager = stateManager
        self.pdfHandler = pdfHandler
        self.payslip = payslip
    }

    // MARK: - Public Methods

    /// Updates the reference to the payslip object
    func updatePayslip(_ payslip: AnyPayslip) {
        self.payslip = payslip
    }

    /// Prints the payslip PDF using the system print dialog
    /// - Parameter presentingVC: The view controller from which to present the print dialog
    func printPDF(from presentingVC: UIViewController) {
        // Use cached data if available
        if let pdfData = pdfHandler.pdfData {
            let jobName = "Payslip - \(payslip.month) \(payslip.year)"
            PrintService.shared.printPDF(pdfData: pdfData, jobName: jobName, from: presentingVC) {
                self.stateManager.dismissPrintDialog()
            }
            return
        }

        // If no cached data, try to get data from URL
        Task {
            do {
                let url = try await pdfHandler.getPDFURL()
                if let url = url {
                    let jobName = "Payslip - \(payslip.month) \(payslip.year)"
                    PrintService.shared.printPDF(url: url, jobName: jobName, from: presentingVC) {
                        self.stateManager.dismissPrintDialog()
                    }
                } else {
                    self.stateManager.handleError(AppError.message("No PDF data available for printing"))
                }
            } catch {
                self.stateManager.handleError(error)
            }
        }
    }

    /// Updates Other Earnings breakdown and saves payslip
    func updateOtherEarnings(_ breakdown: [String: Double]) async {
        guard let payslipItem = payslip as? PayslipItem else { return }

        // Store the original "Other Earnings" amount before clearing
        let originalOtherEarnings = payslipItem.earnings["Other Earnings"] ?? 0

        // Remove old breakdown items from earnings (but keep standard fields)
        let standardFields = ["Basic Pay", "Dearness Allowance", "Military Service Pay"]
        payslipItem.earnings = payslipItem.earnings.filter { standardFields.contains($0.key) }

        // Add new breakdown items
        for (key, value) in breakdown {
            payslipItem.earnings[key] = value
        }

        // Calculate breakdown total
        let breakdownTotal = breakdown.values.reduce(0, +)

        // Calculate remaining unaccounted amount
        let remaining = originalOtherEarnings - breakdownTotal

        // Only add "Other Earnings" if there's a remaining balance
        if remaining > 0.01 {  // Use small epsilon to avoid floating point issues
            payslipItem.earnings["Other Earnings"] = remaining
        }

        // Recalculate gross pay (use original amount for accurate totaling)
        let basicPay = payslipItem.earnings["Basic Pay"] ?? 0
        let da = payslipItem.earnings["Dearness Allowance"] ?? 0
        let msp = payslipItem.earnings["Military Service Pay"] ?? 0
        payslipItem.credits = basicPay + da + msp + originalOtherEarnings

        await saveAndNotify(payslipItem)
    }

    /// Updates Other Deductions breakdown and saves payslip
    func updateOtherDeductions(_ breakdown: [String: Double]) async {
        guard let payslipItem = payslip as? PayslipItem else { return }

        // Store the original "Other Deductions" amount before clearing
        let originalOtherDeductions = payslipItem.deductions["Other Deductions"] ?? 0

        // Remove old breakdown items from deductions (but keep standard fields)
        let standardFields = ["DSOP", "AGIF", "Income Tax"]
        payslipItem.deductions = payslipItem.deductions.filter { standardFields.contains($0.key) }

        // Add new breakdown items
        for (key, value) in breakdown {
            payslipItem.deductions[key] = value
        }

        // Calculate breakdown total
        let breakdownTotal = breakdown.values.reduce(0, +)

        // Calculate remaining unaccounted amount
        let remaining = originalOtherDeductions - breakdownTotal

        // Only add "Other Deductions" if there's a remaining balance
        if remaining > 0.01 {  // Use small epsilon to avoid floating point issues
            payslipItem.deductions["Other Deductions"] = remaining
        }

        // Recalculate total deductions (use original amount for accurate totaling)
        let dsop = payslipItem.deductions["DSOP"] ?? 0
        let agif = payslipItem.deductions["AGIF"] ?? 0
        let tax = payslipItem.deductions["Income Tax"] ?? 0
        payslipItem.debits = dsop + agif + tax + originalOtherDeductions

        await saveAndNotify(payslipItem)
    }

    // MARK: - Private Methods

    private func saveAndNotify(_ payslipItem: PayslipItem) async {
        do {
            let repository = DIContainer.shared.makeSendablePayslipRepository()
            let payslipDTO = PayslipDTO(from: payslipItem)
            _ = try await repository.savePayslip(payslipDTO)

            // Update local state via StateManager
            // Note: StateManager.updatePayslipData also saves, but here we already modified the item
            // So we just update the published property in StateManager
            stateManager.payslipData = PayslipData(from: payslipItem)

            // Post notification
            NotificationCenter.default.post(name: AppNotification.payslipUpdated, object: nil)
        } catch {
            print("[PayslipDetailActionsHandler] Failed to save payslip: \(error)")
            stateManager.handleError(error)
        }
    }
}
