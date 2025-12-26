import SwiftUI
import SwiftData
import PDFKit
import UIKit

/// Main tab view with navigation for the app
struct MainTabView: View {
    // Navigation router (injected)
    @StateObject private var router: NavRouter

    // Global systems
    @StateObject private var transitionCoordinator = TabTransitionCoordinator.shared
    @StateObject private var loadingManager = GlobalLoadingManager.shared

    // Destination factory for creating views
    private let destinationFactory: DestinationFactoryProtocol

    // Access performance debug settings
    @StateObject private var performanceSettings = PerformanceDebugSettings.shared

    // Parsing progress service for badge indicator
    @ObservedObject private var parsingProgress = PayslipParsingProgressService.shared

    // Default parameterless initializer with dependency resolution
    init() {
        // Use DIContainer to resolve dependencies
        let container = DIContainer.shared
        let router = NavRouter()

        self._router = StateObject(wrappedValue: router)
        self.destinationFactory = container.makeDestinationFactory()
    }

    // Initializer with explicit dependencies for testing and previews
    init(router: NavRouter, factory: DestinationFactoryProtocol) {
        self._router = StateObject(wrappedValue: router)
        self.destinationFactory = factory
    }

    var body: some View {
        ZStack {
            // Main tab content
            TabView(selection: $transitionCoordinator.selectedTab) {
                // Home Tab
                NavigationStack(path: $router.homeStack) {
                    HomeView(viewModel: destinationFactory.makeHomeViewModel())
                        .navigationDestination(for: AppNavigationDestination.self) { destination in
                            destinationFactory.makeDestinationView(for: destination)
                        }
                        .withPerformanceDebugToggle()
                        .environment(\.tabSelection, $transitionCoordinator.selectedTab)
                }
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
                .accessibilityIdentifier("Home")

                // Payslips Tab
                NavigationStack(path: $router.payslipsStack) {
                    PayslipsView(viewModel: DIContainer.shared.makePayslipsViewModel())
                        .navigationDestination(for: AppNavigationDestination.self) { destination in
                            destinationFactory.makeDestinationView(for: destination)
                        }
                        .withPerformanceDebugToggle()
                        .environment(\.tabSelection, $transitionCoordinator.selectedTab)
                }
                .tabItem {
                    Label("Payslips", systemImage: "doc.text.fill")
                }
                .badge(parsingProgress.hasNewPayslip ? "New" : nil)
                .tag(1)
                .accessibilityIdentifier("Payslips")

                // Insights Tab
                NavigationStack(path: $router.insightsStack) {
                    InsightsView(coordinator: destinationFactory.makeInsightsCoordinator())
                        .navigationDestination(for: AppNavigationDestination.self) { destination in
                            destinationFactory.makeDestinationView(for: destination)
                        }
                        .withPerformanceDebugToggle()
                        .environment(\.tabSelection, $transitionCoordinator.selectedTab)
                }
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }
                .tag(2)
                .accessibilityIdentifier("Insights")

                // Settings Tab
                NavigationStack(path: $router.settingsStack) {
                    SettingsView(viewModel: destinationFactory.makeSettingsViewModel())
                        .navigationDestination(for: AppNavigationDestination.self) { destination in
                            destinationFactory.makeDestinationView(for: destination)
                        }
                        .withPerformanceDebugToggle()
                        .environment(\.tabSelection, $transitionCoordinator.selectedTab)
                }
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
                .accessibilityIdentifier("Settings")
            }
            .animation(.easeInOut(duration: 0.25), value: transitionCoordinator.selectedTab)

            // Global overlay system
            GlobalOverlayContainer()
                .allowsHitTesting(loadingManager.isLoading || !GlobalOverlaySystem.shared.activeOverlays.isEmpty)
        }
        .sheet(item: $router.sheetDestination) { destination in
            destinationFactory.makeModalView(for: destination, isSheet: true, onDismiss: {
                router.dismissSheet()
            })
        }
        .fullScreenCover(item: $router.fullScreenDestination) { destination in
            destinationFactory.makeModalView(for: destination, isSheet: false, onDismiss: {
                router.dismissFullScreen()
            })
        }
        .environmentObject(router)
        .environmentObject(transitionCoordinator)
        .environmentObject(loadingManager)
        .onAppear {
            setupIntegration()
            configureAppearance()
            startPerformanceMonitoring()
        }
        .onChange(of: transitionCoordinator.selectedTab) { oldValue, newValue in
            // Sync with router (but don't trigger notifications here)
            router.selectedTab = newValue

            // Clear "new payslip" badge when user switches to Payslips tab
            if newValue == 1 { // Payslips tab
                parsingProgress.clearNewPayslipBadge()
            }

            // Log transition for debugging
            print("🔄 MainTabView: Tab changed from \(oldValue) to \(newValue)")
        }
        .accessibilityIdentifier("main_tab_bar")
        .trackPerformance(name: "MainTabView")
    }

    // MARK: - Private Methods

    /// Sets up integration between systems
    private func setupIntegration() {
        // Integrate transition coordinator with router
        transitionCoordinator.integrateWithRouter(router)

        // Sync initial states
        transitionCoordinator.selectedTab = router.selectedTab
    }

    /// Configures app appearance
    private func configureAppearance() {
        // Configure app appearance
        AppearanceManager.shared.configureTabBarAppearance()

        // Check if we're running UI tests
        if ProcessInfo.processInfo.arguments.contains("UI_TESTING") {
            // Special setup for UI test mode
            AppearanceManager.shared.setupForUITesting()
        }
    }

    /// Starts performance monitoring
    private func startPerformanceMonitoring() {
        // Start performance monitoring
        PerformanceMetrics.shared.startMonitoring()
    }
}

// MARK: - Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        // Simple preview with minimal dependencies
        let container = DIContainer.shared
        let router = NavRouter()
        let factory = container.makeDestinationFactory()

        MainTabView(router: router, factory: factory)
            .previewDisplayName("Default")
    }
}
