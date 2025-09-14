import Foundation
import SwiftUI
import Combine
import PDFKit

/// A handler for payslip data operations
@MainActor
class PayslipDataHandler {
    /// The data service for fetching and saving data
    private let dataService: DataServiceProtocol

    /// Flag indicating whether the data service is initialized
    private var isServiceInitialized: Bool {
        dataService.isInitialized
    }

    /// Initializes a new payslip data handler
    /// - Parameter dataService: The data service to use
    init(dataService: DataServiceProtocol) {
        self.dataService = dataService
    }

    /// Loads recent payslips
    /// - Returns: An array of payslip items
    func loadRecentPayslips() async throws -> [AnyPayslip] {
        // Initialize the data service if it's not already initialized
        if !isServiceInitialized {
            try await dataService.initialize()
        }

        // Fetch fresh payslips from data service, forcing a refresh
        let payslips = try await dataService.fetchRefreshed(PayslipItem.self)

        // Only log in non-test environments to reduce test verbosity
        if !ProcessInfo.isRunningInTestEnvironment {
            print("PayslipDataHandler: Loaded \(payslips.count) payslips")
        }

        // Sort by date (newest first)
        return payslips.sorted { $0.timestamp > $1.timestamp }
    }

    /// Saves a payslip item
    /// - Parameter payslipItem: The payslip item to save
    func savePayslipItem(_ payslipItem: PayslipItem) async throws {
        // Initialize the data service if it's not already initialized
        if !isServiceInitialized {
            try await dataService.initialize()
        }

        // Save the payslip item
        try await dataService.save(payslipItem)

        // Save the PDF to the PDFManager if it exists
        if let pdfData = payslipItem.pdfData, !pdfData.isEmpty {
            do {
                let pdfURL = try PDFManager.shared.savePDF(data: pdfData, identifier: payslipItem.id.uuidString)
                print("[PayslipDataHandler] PDF saved at: \(pdfURL.path)")

                // Verify the saved PDF can be loaded
                if PDFDocument(url: pdfURL) != nil {
                    print("[PayslipDataHandler] Successfully verified saved PDF")
                } else {
                    print("[PayslipDataHandler] WARNING: Saved PDF cannot be loaded directly")
                    // Try using the repair function to save a viewable version
                    let repairedData = PDFManager.shared.verifyAndRepairPDF(data: pdfData)
                    let repairedURL = try PDFManager.shared.savePDF(data: repairedData, identifier: "\(payslipItem.id.uuidString)_repaired")
                    print("[PayslipDataHandler] Repaired PDF saved at: \(repairedURL.path)")
                }
            } catch {
                print("[PayslipDataHandler] Error saving PDF: \(error.localizedDescription)")
            }
        }
    }

    /// Backward compatibility method that forwards to savePayslipItem
    /// - Parameter payslipItem: The payslip item to save
    func savePayslip(_ payslipItem: PayslipItem) async throws {
        try await savePayslipItem(payslipItem)
    }

    /// Deletes a payslip item
    /// - Parameter payslipItem: The payslip item to delete
    func deletePayslipItem(_ payslipItem: PayslipItem) async throws {
        // Initialize the data service if it's not already initialized
        if !isServiceInitialized {
            try await dataService.initialize()
        }

        // Delete the payslip item
        try await dataService.delete(payslipItem)
    }

    /// Creates a payslip item from manual entry data
    /// - Parameter manualData: The manual entry data
    /// - Returns: A payslip item
    func createPayslipItemFromManualData(_ manualData: PayslipManualEntryData) -> PayslipItem {
        let payslipItem = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: manualData.month,
            year: manualData.year,
            credits: manualData.credits,
            debits: manualData.debits,
            dsop: manualData.dsop,
            tax: manualData.tax,
            name: manualData.name,
            accountNumber: manualData.accountNumber,
            panNumber: manualData.panNumber,
            pdfData: nil
        )

        // Set earnings and deductions from the manual data
        payslipItem.earnings = manualData.earnings
        payslipItem.deductions = manualData.deductions

        // Set additional metadata
        payslipItem.source = manualData.source
        payslipItem.notes = manualData.notes

        // Calculate totals if they don't match the provided values
        let calculatedCredits = manualData.earnings.values.reduce(0, +)
        let calculatedDebits = manualData.deductions.values.reduce(0, +)

        // If the calculated values don't match the provided totals, adjust
        if calculatedCredits != manualData.credits && calculatedCredits > 0 {
            payslipItem.credits = calculatedCredits
        }

        if calculatedDebits != manualData.debits && calculatedDebits > 0 {
            payslipItem.debits = calculatedDebits
        }

        return payslipItem
    }

    /// Creates a payslip from manual entry (alias for createPayslipItemFromManualData)
    /// - Parameter data: The manual entry data
    /// - Returns: A payslip item
    func createPayslipFromManualEntry(_ data: PayslipManualEntryData) -> PayslipItem {
        return createPayslipItemFromManualData(data)
    }
}
