import Foundation
import SwiftUI
import SwiftData
import Combine

/// Represents the app's theme/appearance mode
enum AppTheme: String, CaseIterable, Identifiable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
    
    var id: String { self.rawValue }
    
    var systemImage: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "gear"
        }
    }
    
    var uiInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return .unspecified
        }
    }
}

@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Whether the view model is loading data.
    @Published var isLoading = false
    
    /// The error to display to the user.
    @Published var error: AppError?
    
    /// Whether the user is authenticated.
    @Published var isAuthenticated = false
    
    /// The user's name.
    @Published var userName = ""
    
    /// The user's email.
    @Published var userEmail = ""
    
    /// Whether to use biometric authentication.
    @Published var useBiometricAuth = false
    
    /// The app's theme/appearance mode
    @Published var appTheme: AppTheme = .system
    
    /// Whether to use dark mode (legacy property, kept for backward compatibility)
    @Published var useDarkMode = false
    
    /// The selected currency.
    @Published var selectedCurrency = "₹ (INR)"
    
    /// The available currencies.
    let availableCurrencies = ["₹ (INR)", "$ (USD)", "€ (EUR)", "£ (GBP)"]
    
    /// The payslips to display.
    @Published var payslips: [any PayslipItemProtocol] = []
    
    // MARK: - Private Properties
    
    /// The security service to use for authentication.
    private let securityService: SecurityServiceProtocol
    
    /// The data service to use for fetching and saving data.
    private let dataService: DataServiceProtocol
    
    /// The user defaults to use for storing preferences.
    private let userDefaults: UserDefaults
    
    /// The cancellables for managing subscriptions.
    private var cancellables = Set<AnyCancellable>()
    
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
        
        // Load theme preference
        if let themeName = userDefaults.string(forKey: "appTheme"),
           let theme = AppTheme(rawValue: themeName) {
            self.appTheme = theme
        } else {
            // For backward compatibility
            self.useDarkMode = userDefaults.bool(forKey: "useDarkMode")
            self.appTheme = useDarkMode ? .dark : .light
        }
        
        self.selectedCurrency = userDefaults.string(forKey: "selectedCurrency") ?? "₹ (INR)"
        
        // Apply appearance preference
        updateAppearance()
    }
    
    // MARK: - Public Methods
    
    /// Refreshes the authentication status.
    func refreshAuthenticationStatus() {
        isLoading = true
        
        // For now, just set a default value to avoid the error
        // In a real app, you would call the appropriate method on the security service
        isAuthenticated = true
        
        if isAuthenticated {
            // Get user info
            // For now, just set default values
            userName = "Demo User"
            userEmail = "demo@example.com"
        }
        
        isLoading = false
    }
    
    /// Signs the user out.
    func signOut() {
        isLoading = true
        
        // For now, just set the values directly to avoid the error
        // In a real app, you would call the appropriate method on the security service
        isAuthenticated = false
        userName = ""
        userEmail = ""
        
        isLoading = false
    }
    
    /// Updates the biometric preference.
    ///
    /// - Parameter enabled: Whether to enable biometric authentication.
    func updateBiometricPreference(enabled: Bool) {
        userDefaults.set(enabled, forKey: "useBiometricAuth")
    }
    
    /// Updates the appearance preference.
    ///
    /// - Parameter darkMode: Whether to enable dark mode.
    func updateAppearancePreference(darkMode: Bool) {
        userDefaults.set(darkMode, forKey: "useDarkMode")
        self.useDarkMode = darkMode
        self.appTheme = darkMode ? .dark : .light
        userDefaults.set(appTheme.rawValue, forKey: "appTheme")
        updateAppearance()
    }
    
    /// Updates the appearance preference with the specified theme.
    ///
    /// - Parameter theme: The theme to use.
    func updateAppearancePreference(theme: AppTheme) {
        userDefaults.set(theme.rawValue, forKey: "appTheme")
        self.appTheme = theme
        // Update legacy property for backward compatibility
        self.useDarkMode = (theme == .dark)
        userDefaults.set(useDarkMode, forKey: "useDarkMode")
        updateAppearance()
    }
    
    /// Updates the currency preference.
    ///
    /// - Parameter currency: The currency to use.
    func updateCurrencyPreference(currency: String) {
        userDefaults.set(currency, forKey: "selectedCurrency")
    }
    
    /// Imports data from a file.
    func importData() {
        // In a real app, you would implement this
        // For now, we'll just show an error
        error = AppError.message("Import functionality not implemented yet")
    }
    
    /// Loads payslips from the data service.
    ///
    /// - Parameter context: The model context to use.
    func loadPayslips(context: ModelContext) {
        isLoading = true
        
        Task {
            do {
                let fetchedPayslips = try await dataService.fetch(PayslipItem.self)
                payslips = fetchedPayslips
                
                isLoading = false
            } catch {
                handleError(error)
                isLoading = false
            }
        }
    }
    
    /// Deletes all data.
    ///
    /// - Parameter context: The model context to use.
    func deleteAllData(context: ModelContext) {
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
                self.payslips = []
                
                isLoading = false
            } catch {
                handleError(error)
                isLoading = false
            }
        }
    }
    
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
                    
                    let payslip = PayslipItem(
                        month: month,
                        year: year,
                        credits: Double.random(in: 30000...50000),
                        debits: Double.random(in: 5000...10000),
                        dsop: Double.random(in: 3000...5000),
                        tax: Double.random(in: 3000...8000),
                        location: "New Delhi",
                        name: "John Doe",
                        accountNumber: "1234567890",
                        panNumber: "ABCDE1234F",
                        timestamp: Calendar.current.date(from: DateComponents(year: year, month: i % 12 + 1, day: 15)) ?? Date()
                    )
                    
                    context.insert(payslip)
                }
                
                try context.save()
                
                // Refresh payslips
                loadPayslips(context: context)
                
                isLoading = false
            } catch {
                handleError(error)
                isLoading = false
            }
        }
    }
    
    /// Clears sample data.
    ///
    /// - Parameter context: The model context to use.
    func clearSampleData(context: ModelContext) {
        deleteAllData(context: context)
    }
    
    // MARK: - Error Handling
    
    /// Clears the current error
    func clearError() {
        self.error = nil
    }
    
    // MARK: - Private Methods
    
    /// Updates the app appearance based on the theme preference.
    private func updateAppearance() {
        if #available(iOS 15.0, *) {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            let window = windowScene?.windows.first
            window?.overrideUserInterfaceStyle = appTheme.uiInterfaceStyle
        }
    }
    
    /// Handles an error.
    ///
    /// - Parameter error: The error to handle.
    private func handleError(_ error: Error) {
        ErrorLogger.log(error)
        self.error = AppError.from(error)
    }
} 