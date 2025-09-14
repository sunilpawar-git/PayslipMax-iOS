import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - Settings ViewModel Actions Extension
// Contains all public action methods for SettingsViewModel
// Follows MVVM pattern with async/await and proper error handling

@MainActor
extension SettingsViewModel {

    // MARK: - Public Action Methods

    /// Updates the biometric preference.
    ///
    /// - Parameter enabled: Whether to enable biometric authentication.
    func updateBiometricPreference(enabled: Bool) {
        userDefaults.set(enabled, forKey: "useBiometricAuth")
        useBiometricAuth = enabled
    }

    /// Updates the appearance preference with the specified theme.
    ///
    /// - Parameter theme: The theme to use.
    func updateAppearancePreference(theme: AppTheme) {
        // Prevent circular updates
        isUpdatingTheme = true

        // Update the theme via ThemeManager which will handle saving and applying
        ThemeManager.shared.setTheme(theme)

        // Update local properties
        appTheme = theme
        useDarkMode = (theme == .dark)

        // Re-enable theme updates after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isUpdatingTheme = false
        }
    }

    /// Loads payslips from the data service.
    ///
    /// - Parameter context: The model context to use.
    func loadPayslips(context: ModelContext) {
        isLoading = true

        Task {
            do {
                // Ensure the data service is initialized
                if let dataService = self.dataService as? DataServiceImpl, !dataService.isInitialized {
                    try await self.dataService.initialize()
                }

                let fetchedPayslips = try await dataService.fetch(PayslipItem.self)
                await MainActor.run {
                    self.payslips = fetchedPayslips
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    // Only report critical errors, ignore data not found errors
                    let nsError = error as NSError
                    // If it's a common data error, like no data found, just silently handle it
                    if nsError.domain == "SwiftDataError" ||
                       nsError.localizedDescription.contains("not found") ||
                       nsError.localizedDescription.contains("no results") {
                        // Just set empty payslips without showing an error
                        self.payslips = []
                    } else {
                        // Only handle serious errors
                        handleError(error)
                    }
                    self.isLoading = false
                }
            }
        }
    }

    /// Exports all payslip data
    func exportData() {
        Task {
            await MainActor.run {
                isLoading = true
            }

            // Create export data
            let exportData = payslips.map { payslip in
                [
                    "month": payslip.month,
                    "year": String(payslip.year),
                    "credits": String(payslip.credits),
                    "debits": String(payslip.debits),
                    "dsop": String(payslip.dsop),
                    "tax": String(payslip.tax),
                    "name": payslip.name,
                    "accountNumber": payslip.accountNumber,
                    "panNumber": payslip.panNumber
                ]
            }

            do {
                let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
                let tempDirectory = FileManager.default.temporaryDirectory
                let fileURL = tempDirectory.appendingPathComponent("payslips_export.json")

                try jsonData.write(to: fileURL)

                await MainActor.run {
                    // Present share sheet
                    let activityViewController = UIActivityViewController(
                        activityItems: [fileURL],
                        applicationActivities: nil
                    )

                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        window.rootViewController?.present(activityViewController, animated: true)
                    }

                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    handleError(AppError.operationFailed("Failed to export data: \(error.localizedDescription)"))
                    isLoading = false
                }
            }
        }
    }

    /// Opens support contact options
    func contactSupport() {
        let supportEmail = "support@payslipmax.com"
        let subject = "PayslipMax Support Request"
        let body = "Hi, I need help with PayslipMax.\n\nDevice: \(UIDevice.current.name)\nOS: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)\n\nIssue:\n"

        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let mailtoString = "mailto:\(supportEmail)?subject=\(encodedSubject)&body=\(encodedBody)"

        if let mailtoURL = URL(string: mailtoString) {
            if UIApplication.shared.canOpenURL(mailtoURL) {
                UIApplication.shared.open(mailtoURL)
            } else {
                // Fallback - copy email to clipboard
                UIPasteboard.general.string = supportEmail
                // Show alert that email was copied
                let alert = UIAlertController(
                    title: "Email Copied",
                    message: "Support email address copied to clipboard: \(supportEmail)",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))

                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first {
                    window.rootViewController?.present(alert, animated: true)
                }
            }
        }
    }

    /// Clears all data.
    ///
    /// - Parameter context: The model context to use.
    func clearAllData(context: ModelContext) {
        isLoading = true

        Task {
            do {
                // Delete all payslips
                let fetchDescriptor = FetchDescriptor<PayslipItem>()
                let payslips = try context.fetch(fetchDescriptor)

                for payslip in payslips {
                    context.delete(payslip)
                }

                try context.save()

                // Notify other ViewModels to refresh their data
                PayslipEvents.notifyForcedRefreshRequired()

                // Refresh payslips
                await MainActor.run {
                    self.payslips = []
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    handleError(error)
                    self.isLoading = false
                }
            }
        }
    }
}
