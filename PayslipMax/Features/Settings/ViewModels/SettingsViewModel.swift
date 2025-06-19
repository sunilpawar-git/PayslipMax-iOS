import Foundation
import SwiftUI
import SwiftData
import Combine

// Remove the Core import and just reference AppTheme directly

@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Whether the view model is loading data.
    @Published var isLoading = false
    
    /// The error to display to the user.
    @Published var error: AppError?
    
    /// Whether to use biometric authentication.
    @Published var useBiometricAuth = false
    
    /// The app's theme/appearance mode - now bound to ThemeManager
    @Published var appTheme: AppTheme = .system
    
    /// Whether to use dark mode (legacy property, kept for backward compatibility)
    @Published var useDarkMode = false
    
    /// The payslips to display.
    @Published var payslips: [AnyPayslip] = []
    
    // MARK: - Private Properties
    
    /// The security service to use for authentication.
    private let securityService: SecurityServiceProtocol
    
    /// The data service to use for fetching and saving data.
    private let dataService: DataServiceProtocol
    
    /// The user defaults to use for storing preferences.
    private let userDefaults: UserDefaults
    
    /// The cancellables for managing subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
    /// Flag to prevent circular updates between theme manager and view model
    private var isUpdatingTheme = false
    
    // MARK: - Initialization
    
    /// Initializes a new SettingsViewModel.
    ///
    /// - Parameters:
    ///   - securityService: The security service to use for authentication.
    ///   - dataService: The data service to use for fetching and saving data.
    ///   - userDefaults: The user defaults to use for storing preferences.
    init(
        securityService: SecurityServiceProtocol? = nil,
        dataService: DataServiceProtocol? = nil,
        userDefaults: UserDefaults = .standard
    ) {
        self.securityService = securityService ?? DIContainer.shared.securityService
        self.dataService = dataService ?? DIContainer.shared.dataService
        self.userDefaults = userDefaults
        
        // Load preferences from user defaults
        self.useBiometricAuth = userDefaults.bool(forKey: "useBiometricAuth")
        
        // Sync with ThemeManager without triggering circular updates
        self.appTheme = ThemeManager.shared.currentTheme
        self.useDarkMode = (appTheme == .dark)
        
        // Set up theme change subscription AFTER initial setup
        setupThemeSubscription()
        
        // Initialize the data service
        Task {
            do {
                if let dataService = self.dataService as? DataServiceImpl, !dataService.isInitialized {
                    try await self.dataService.initialize()
                }
            } catch {
                await MainActor.run {
                    // Log error but don't show to user yet - wait until they actually try to use it
                    ErrorLogger.log(error)
                }
            }
        }
    }
    
    /// Sets up the subscription to theme changes from ThemeManager
    private func setupThemeSubscription() {
        ThemeManager.shared.$currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newTheme in
                guard let self = self, !self.isUpdatingTheme else { return }
                
                self.appTheme = newTheme
                self.useDarkMode = (newTheme == .dark)
            }
            .store(in: &cancellables)
    }
    
    /// Deinitializer to clean up subscriptions and prevent memory leaks
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Public Methods
    
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
                    isLoading = false
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
                
                // Refresh payslips
                await MainActor.run {
                    self.payslips = []
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    handleError(error)
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Error Handling
    
    /// Clears the current error
    func clearError() {
        self.error = nil
    }
    
    // MARK: - Private Methods
    
    /// Handles an error.
    ///
    /// - Parameter error: The error to handle.
    private func handleError(_ error: Error) {
        if let appError = error as? AppError {
            self.error = appError
        } else {
            self.error = AppError.operationFailed(error.localizedDescription)
        }
    }
} 