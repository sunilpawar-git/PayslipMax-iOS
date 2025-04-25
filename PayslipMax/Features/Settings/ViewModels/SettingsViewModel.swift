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
    
    /// The app's theme/appearance mode
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
        
        // Apply appearance preference
        updateAppearance()
        
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
    
    // MARK: - Public Methods
    
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
        deleteAllData(context: context)
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
    #endif
    
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
        
        // If it's already an AppError, use it directly
        if let appError = error as? AppError {
            self.error = appError
            return
        }
        
        // Convert common NSError types to more descriptive AppErrors
        let nsError = error as NSError
        
        // SwiftData/CoreData errors (which seem to be occurring in Settings)
        if nsError.domain.contains("CoreData") || nsError.domain.contains("SwiftData") {
            self.error = AppError.fetchFailed("Settings data (code: \(nsError.code))")
            return
        }
        
        // Network errors
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet:
                self.error = AppError.networkConnectionLost
            case NSURLErrorTimedOut:
                self.error = AppError.timeoutError
            default:
                self.error = AppError.operationFailed("Network error: \(nsError.localizedDescription)")
            }
            return
        }
        
        // Generic error handling
        self.error = AppError.operationFailed("Error in Settings: \(nsError.localizedDescription)")
    }
} 