//
//  PayslipMaxApp.swift
//  PayslipMax
//
//  Created by Sunil on 21/01/25.
//

import SwiftUI
import SwiftData

@main
struct PayslipMaxApp: App {
    @StateObject private var router = NavRouter()
    @StateObject private var deepLinkCoordinator: DeepLinkCoordinator
    let modelContainer: ModelContainer
    
    init() {
        // Initialize router first
        let initialRouter = NavRouter()
        _router = StateObject(wrappedValue: initialRouter)
        // Initialize deep link coordinator, injecting the router
        _deepLinkCoordinator = StateObject(wrappedValue: DeepLinkCoordinator(router: initialRouter))
        
        // Register the router with AppContainer using the protocol metatype
        AppContainer.shared.register((any RouterProtocol).self, instance: initialRouter)
        
        do {
            let schema = Schema([PayslipItem.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: ProcessInfo.processInfo.arguments.contains("UI_TESTING"))
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Set up test data if running UI tests
            if ProcessInfo.processInfo.arguments.contains("UI_TESTING") {
                setupTestData()
                // Configure UI for testing
                AppearanceManager.shared.setupForUITesting()
            }
            
            // Configure app appearance
            AppearanceManager.shared.configureTabBarAppearance()
            AppearanceManager.shared.configureNavigationBarAppearance()
            
            // Apply the saved theme
            applyAppTheme()
            
            // Initialize encryption services
            setupEncryptionServices()
            
            // Initialize performance debug settings with warnings disabled by default
            setupPerformanceDebugging()
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    /// Applies the saved app theme
    private func applyAppTheme() {
        let userDefaults = UserDefaults.standard
        
        // Get the saved theme
        if let themeName = userDefaults.string(forKey: "appTheme"),
           let theme = AppTheme(rawValue: themeName) {
            applyTheme(theme)
        } else {
            // For backward compatibility
            let useDarkMode = userDefaults.bool(forKey: "useDarkMode")
            applyTheme(useDarkMode ? .dark : .light)
        }
    }
    
    /// Applies the specified theme
    private func applyTheme(_ theme: AppTheme) {
        if #available(iOS 15.0, *) {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            let window = windowScene?.windows.first
            window?.overrideUserInterfaceStyle = theme.uiInterfaceStyle
        }
    }
    
    /// Sets up encryption services for the app
    private func setupEncryptionServices() {
        // Initialize the security service
        Task {
            do {
                try await DIContainer.shared.securityService.initialize()
                print("Security service initialized successfully")
                
                // Initialize the PayslipSensitiveDataHandler factory
                PayslipSensitiveDataHandler.Factory.initialize()
                
                // Create an adapter that makes SecurityServiceImpl conform to SensitiveDataEncryptionService
                let securityService = DIContainer.shared.securityService
                let encryptionServiceAdapter = SecurityServiceAdapter(securityService: securityService)
                
                // Configure with the adapter and store the result
                let result = PayslipSensitiveDataHandler.Factory.setSensitiveDataEncryptionServiceFactory {
                    return encryptionServiceAdapter
                }
                
                print("Encryption service factory configured successfully: \(result)")
            } catch {
                print("Failed to initialize security service: \(error)")
            }
        }
    }
    
    /// Adapter to make SecurityServiceImpl conform to SensitiveDataEncryptionService
    private class SecurityServiceAdapter: SensitiveDataEncryptionService {
        private let securityService: SecurityServiceProtocol
        
        init(securityService: SecurityServiceProtocol) {
            self.securityService = securityService
        }
        
        func encrypt(_ data: Data) throws -> Data {
            // Create a synchronous wrapper around the async method
            let semaphore = DispatchSemaphore(value: 0)
            var resultData: Data?
            var resultError: Error?
            
            Task {
                do {
                    resultData = try await securityService.encryptData(data)
                } catch {
                    resultError = error
                }
                semaphore.signal()
            }
            
            semaphore.wait()
            
            if let error = resultError {
                throw error
            }
            
            guard let encryptedData = resultData else {
                throw SensitiveDataError.encryptionServiceCreationFailed
            }
            
            return encryptedData
        }
        
        func decrypt(_ data: Data) throws -> Data {
            // Create a synchronous wrapper around the async method
            let semaphore = DispatchSemaphore(value: 0)
            var resultData: Data?
            var resultError: Error?
            
            Task {
                do {
                    resultData = try await securityService.decryptData(data)
                } catch {
                    resultError = error
                }
                semaphore.signal()
            }
            
            semaphore.wait()
            
            if let error = resultError {
                throw error
            }
            
            guard let decryptedData = resultData else {
                throw SensitiveDataError.encryptionServiceCreationFailed
            }
            
            return decryptedData
        }
    }

    var body: some Scene {
        WindowGroup {
            if ProcessInfo.processInfo.arguments.contains("UI_TESTING") {
                // Bypass authentication during UI testing
                AppNavigationView()
                    .modelContainer(modelContainer)
                    .environmentObject(router)
                    .onOpenURL { url in
                        // Handle deep links using the coordinator
                        _ = deepLinkCoordinator.handleDeepLink(url)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                        // Reapply theme when app becomes active
                        applyAppTheme()
                    }
            } else {
                BiometricAuthView {
                    AppNavigationView()
                        .modelContainer(modelContainer)
                        .environmentObject(router)
                        .onOpenURL { url in
                            // Handle deep links using the coordinator
                            _ = deepLinkCoordinator.handleDeepLink(url)
                        }
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                            // Reapply theme when app becomes active
                            applyAppTheme()
                        }
                }
            }
        }
    }
    
    private func setupTestData() {
        let context = modelContainer.mainContext
        
        // Create test payslips
        let testPayslips = [
            PayslipItem(
                id: UUID(),
                timestamp: Date().addingTimeInterval(-86400 * 60),
                month: "January",
                year: 2024,
                credits: 5000,
                debits: 1000,
                dsop: 500,
                tax: 800,
                name: "Test User",
                accountNumber: "1234567890",
                panNumber: "ABCDE1234F",
                pdfData: nil
            ),
            PayslipItem(
                id: UUID(),
                timestamp: Date().addingTimeInterval(-86400 * 30),
                month: "February",
                year: 2024,
                credits: 5500,
                debits: 1100,
                dsop: 550,
                tax: 880,
                name: "Test User",
                accountNumber: "1234567890",
                panNumber: "ABCDE1234F",
                pdfData: nil
            ),
            PayslipItem(
                id: UUID(),
                timestamp: Date(),
                month: "March",
                year: 2024,
                credits: 6000,
                debits: 1200,
                dsop: 600,
                tax: 960,
                name: "Test User",
                accountNumber: "1234567890",
                panNumber: "ABCDE1234F",
                pdfData: nil
            )
        ]
        
        // Add test payslips to the context
        for payslip in testPayslips {
            context.insert(payslip)
        }
        
        // Save the context
        try? context.save()
    }
    
    /// Sets up performance debugging options
    private func setupPerformanceDebugging() {
        #if DEBUG
        // Ensure performance warnings are disabled by default
        if !UserDefaults.standard.bool(forKey: "isPerformanceWarningLogsEnabled") {
            // Only modify if the user hasn't explicitly changed the setting
            UserDefaults.standard.set(false, forKey: "isPerformanceWarningLogsEnabled")
            ViewPerformanceTracker.shared.isLogWarningsEnabled = false
        }
        
        // Print initial state message to console
        print("ℹ️ Performance tracking system initialized. Use the hammer icon in navigation bar to toggle performance warnings.")
        #endif
    }
}
