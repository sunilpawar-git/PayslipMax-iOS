//
//  PayslipMaxApp.swift
//  PayslipMax
//
//  Created by Sunil on 21/01/25.
//
import SwiftUI
import SwiftData
import FirebaseCore

@main
struct PayslipMaxApp: App {
    @StateObject private var router: NavRouter
    @StateObject private var deepLinkCoordinator: DeepLinkCoordinator
    @StateObject private var asyncSecurityCoordinator = AsyncSecurityCoordinator()
    @ObservedObject private var themeManager = ThemeManager.shared
    let modelContainer: ModelContainer

    init() {
        FirebaseApp.configure()
        Task {
            do {
                let authService = AnonymousAuthService()
                _ = try await authService.ensureAuthenticated()
            } catch {
                #if DEBUG
                print("⚠️ Failed to authenticate anonymously: \(error.localizedDescription)")
                #endif
            }
        }
        let initialRouter = NavRouter()
        _router = StateObject(wrappedValue: initialRouter)
        _deepLinkCoordinator = StateObject(wrappedValue: DeepLinkCoordinator(router: initialRouter))
        AppContainer.shared.register((any RouterProtocol).self, instance: initialRouter)
        do {
            let schema = Schema([PayslipItem.self, LLMUsageRecord.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: ProcessInfo.processInfo.arguments.contains("UI_TESTING"))
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            AppContainer.shared.register(ModelContainer.self, instance: modelContainer)

            // Set up test data if running UI tests
            if ProcessInfo.processInfo.arguments.contains("UI_TESTING") {
                setupTestData()
                // Configure UI for testing
                AppearanceManager.shared.setupForUITesting()
            }

            // Configure app appearance
            AppearanceManager.shared.configureTabBarAppearance()
            AppearanceManager.shared.configureNavigationBarAppearance()

            // Initialize theme manager
            _ = ThemeManager.shared

            // Initialize performance debug settings with warnings disabled by default
            setupPerformanceDebugging()

            // Perform first-run setup
            let firstRunService = FirstRunService()
            firstRunService.performFirstRunSetupIfNeeded()

            // Log startup diagnostics (Debug only)
            StartupDiagnostics.logConfiguration()
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }

    /// Check if biometric authentication is enabled by user
    private var isBiometricAuthEnabled: Bool {
        UserDefaults.standard.bool(forKey: "useBiometricAuth")
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if ProcessInfo.processInfo.arguments.contains("UI_TESTING") {
                    // Bypass splash and authentication during UI testing
                    authenticationView
                } else {
                    // Always show splash screen first, then authentication
                    SplashContainerView {
                        authenticationView
                    }
                }
            }
            // ✅ FIX: Apply preferredColorScheme from ThemeManager for consistent SwiftUI theme
            .preferredColorScheme(themeManager.currentTheme.colorScheme)
            // ✅ CLEAN: Initialize security coordinator synchronously
            .onAppear {
                asyncSecurityCoordinator.initialize()

                // ✅ FIX: Apply theme after window is ready (fixes race condition)
                themeManager.applyInitialThemeIfNeeded()

                // ✅ NEW: Initialize and validate parsing systems
                validateParsingSystemsAtStartup()
            }
            // ✅ CLEAN: Configure async factory in task
            .task {
                // Configure async sensitive data factory
                AsyncSensitiveDataHandler.Factory.setAsyncEncryptionServiceFactory {
                    try self.asyncSecurityCoordinator.getAsyncEncryptionService()
                }

                print("✅ Async security services configured successfully")
            }
        }
    }

    /// Validates parsing systems at startup to ensure JSON and pattern loading works correctly
    private func validateParsingSystemsAtStartup() {
        print("🚀 PayslipMax Parsing Systems Validation:")

        // 1. Validate PatternProvider (universal parsing patterns)
        let patternProvider = DefaultPatternProvider()
        print("   • Legacy Regex Patterns: \(patternProvider.patterns.count)")
        print("   • Earnings Patterns: \(patternProvider.earningsPatterns.count)")
        print("   • Deductions Patterns: \(patternProvider.deductionsPatterns.count)")

        // 2. Validate MilitaryAbbreviationsService (243 JSON codes)
        let militaryService = MilitaryAbbreviationsService.shared
        let jsonCount = militaryService.allAbbreviations.count
        let creditCount = militaryService.creditAbbreviations.count
        let debitCount = militaryService.debitAbbreviations.count

        print("   • JSON Military Codes: \(jsonCount)")
        print("   • Credit Classifications: \(creditCount)")
        print("   • Debit Classifications: \(debitCount)")

        // 3. Validate UniversalPayCodeSearchEngine (combined system)
        let patternGenerator = PayCodePatternGenerator.shared
        let totalSearchCodes = patternGenerator.getAllKnownPayCodes().count
        print("   • Universal Search Codes: \(totalSearchCodes)")

        // 4. Critical validation checks
        var warnings: [String] = []

        if jsonCount < 200 {
            warnings.append("🚨 JSON SYSTEM CRITICAL: Expected ~243 codes, got \(jsonCount)")
        }

        // Critical validation: Pay code count
        // JSON: 243 codes | Hardcoded: 32 codes | After deduplication: ~246 codes
        if totalSearchCodes < 240 {
            warnings.append("🚨 SEARCH SYSTEM CRITICAL: Expected ~246 codes, got \(totalSearchCodes)")
        }


        if patternProvider.patterns.count < 40 {
            warnings.append("⚠️ PATTERN SYSTEM WARNING: Expected ~51 patterns, got \(patternProvider.patterns.count)")
        }

        // 5. Dual-section validation and arrears processing
        if jsonCount > 0 {
            // Check for dual-section codes (isCredit: null)
            let dualSectionCodes = militaryService.allAbbreviations.filter { $0.isCredit == nil }
            print("   • Dual-Section Codes: \(dualSectionCodes.count)")

            // Test specific dual-section codes
            if let rhCode = militaryService.abbreviation(forCode: "RH12") {
                let classification = rhCode.isCredit == nil ? "Dual" :
                    rhCode.isCredit == true ? "Credit-Only" : "Debit-Only"
                print("   • RH12 Classification: \(rhCode.description) (\(classification))")
            }

            if let hraCode = militaryService.abbreviation(forCode: "HRA") {
                let classification = hraCode.isCredit == nil ? "Dual" :
                    hraCode.isCredit == true ? "Credit-Only" : "Debit-Only"
                print("   • HRA Classification: \(hraCode.description) (\(classification))")
            }

            // Validate arrears processing capability
            if let ceaCode = militaryService.abbreviation(forCode: "CEA") {
                let classification = ceaCode.isCredit == nil ? "Dual" :
                    ceaCode.isCredit == true ? "Credit-Only" : "Debit-Only"
                print("   • CEA (Arrears Base): \(ceaCode.description) (\(classification))")
            }

            // Critical dual-section validation
            if dualSectionCodes.isEmpty {
                warnings.append("🚨 DUAL-SECTION CRITICAL: No codes with isCredit:null found - Universal processing may be limited")
            }
        }

        // 6. Report results
        let totalCoverage = patternProvider.patterns.count + jsonCount
        print("   • Total Parsing Coverage: \(totalCoverage) patterns/codes")

        if warnings.isEmpty {
            print("✅ All parsing systems initialized successfully")
            print("🎯 Universal Dual-Section Processing: ACTIVE (243 codes in both earnings and deductions)")
        } else {
            for warning in warnings {
                print(warning)
            }
        }

        print("🔍 Startup validation completed")
    }

    /// Authentication view that handles biometric auth if enabled
    private var authenticationView: some View {
        Group {
            if isBiometricAuthEnabled {
                // Show biometric authentication (without splash - handled by container)
                BiometricAuthView {
                    mainAppView
                }
            } else {
                // Go directly to app if biometric authentication is disabled
                mainAppView
            }
        }
    }

    /// The main app view with common configuration
    private var mainAppView: some View {
        AppNavigationView()
            .modelContainer(modelContainer)
            .environmentObject(router)
            .environmentObject(asyncSecurityCoordinator)
            .onOpenURL { url in
                // Handle deep links using the coordinator
                _ = deepLinkCoordinator.handleDeepLink(url)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Reapply theme when app becomes active (ensures consistency after background)
                themeManager.applyTheme(themeManager.currentTheme)
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
        print("ℹ️ Performance tracking system initialized. Use the hammer icon in navigation bar to toggle performance warnings.")
        #endif
    }
}
