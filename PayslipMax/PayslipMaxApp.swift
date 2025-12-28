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
                    authenticationView
                } else {
                    SplashContainerView {
                        authenticationView
                    }
                }
            }
            .preferredColorScheme(themeManager.currentTheme.colorScheme)
            .onAppear {
                asyncSecurityCoordinator.initialize()
                themeManager.applyInitialThemeIfNeeded()
                validateParsingSystemsAtStartup()
            }
            .task {
                AsyncSensitiveDataHandler.Factory.setAsyncEncryptionServiceFactory {
                    try self.asyncSecurityCoordinator.getAsyncEncryptionService()
                }
                print("✅ Async security services configured successfully")
            }
        }
    }

    /// Authentication view that handles biometric auth if enabled
    private var authenticationView: some View {
        Group {
            if isBiometricAuthEnabled {
                BiometricAuthView {
                    mainAppView
                }
            } else {
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
                _ = deepLinkCoordinator.handleDeepLink(url)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                themeManager.applyTheme(themeManager.currentTheme)
            }
    }

    /// Sets up performance debugging options
    private func setupPerformanceDebugging() {
        #if DEBUG
        if !UserDefaults.standard.bool(forKey: "isPerformanceWarningLogsEnabled") {
            UserDefaults.standard.set(false, forKey: "isPerformanceWarningLogsEnabled")
            ViewPerformanceTracker.shared.isLogWarningsEnabled = false
        }
        print("ℹ️ Performance tracking system initialized. Use the hammer icon in navigation bar to toggle performance warnings.")
        #endif
    }
}
