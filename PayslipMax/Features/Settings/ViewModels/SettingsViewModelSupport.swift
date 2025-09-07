import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - Settings ViewModel Support Extension
// Contains error handling, debug methods, and utility functions
// Follows MVVM pattern with proper error management

@MainActor
extension SettingsViewModel {

    // MARK: - Error Handling

    /// Clears the current error
    func clearError() {
        self.error = nil
    }

    // MARK: - Private Methods

    /// Handles an error.
    ///
    /// - Parameter error: The error to handle.
    func handleError(_ error: Error) {
        if let appError = error as? AppError {
            self.error = appError
        } else {
            self.error = AppError.operationFailed(error.localizedDescription)
        }
    }

    // MARK: - Debug Methods

    #if DEBUG
    /// Generates sample data for testing.
    ///
    /// - Parameter context: The model context to use.
    func generateSampleData(context: ModelContext) {
        isLoading = true

        Task {
            do {
                // Generate sample payslips
                let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
                let currentYear = Calendar.current.component(.year, from: Date())

                for i in 0..<12 {
                    let month = months[i % 12]
                    let year = currentYear - (i / 12)
                    let timestamp = Calendar.current.date(from: DateComponents(year: year, month: i % 12 + 1, day: 15)) ?? Date()

                    let payslip = PayslipItem(
                        id: UUID(),
                        timestamp: timestamp,
                        month: month,
                        year: year,
                        credits: Double.random(in: 30000...50000),
                        debits: Double.random(in: 5000...10000),
                        dsop: Double.random(in: 3000...5000),
                        tax: Double.random(in: 3000...8000),
                        name: "John Doe",
                        accountNumber: "1234567890",
                        panNumber: "ABCDE1234F",
                        pdfData: nil
                    )

                    context.insert(payslip)
                }

                try context.save()

                // Refresh payslips
                await MainActor.run {
                    self.isLoading = false
                }
                loadPayslips(context: context)
            } catch {
                await MainActor.run {
                    handleError(error)
                    self.isLoading = false
                }
            }
        }
    }

    /// Clears sample data.
    ///
    /// - Parameter context: The model context to use.
    func clearSampleData(context: ModelContext) {
        clearAllData(context: context)
    }
    #endif
}
