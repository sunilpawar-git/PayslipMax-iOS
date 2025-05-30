import SwiftUI
import SwiftData
import PDFKit
import UIKit

/// Main tab view with navigation for the app
struct MainTabView: View {
    // Navigation router (injected)
    @StateObject private var router: NavRouter
    
    // Destination factory for creating views
    private let destinationFactory: DestinationFactoryProtocol
    
    // Access performance debug settings
    @StateObject private var performanceSettings = PerformanceDebugSettings.shared
    
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
        TabView(selection: $router.selectedTab) {
            // Home Tab
            NavigationStack(path: $router.homeStack) {
                HomeView()
                    .navigationDestination(for: AppNavigationDestination.self) { destination in
                        destinationFactory.makeDestinationView(for: destination)
                    }
                    .withPerformanceDebugToggle()
                    .environment(\.tabSelection, $router.selectedTab)
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
                    .environment(\.tabSelection, $router.selectedTab)
            }
            .tabItem {
                Label("Payslips", systemImage: "doc.text.fill")
            }
            .tag(1)
            .accessibilityIdentifier("Payslips")
            
            // Insights Tab
            NavigationStack(path: $router.insightsStack) {
                InsightsView()
                    .navigationDestination(for: AppNavigationDestination.self) { destination in
                        destinationFactory.makeDestinationView(for: destination)
                    }
                    .withPerformanceDebugToggle()
                    .environment(\.tabSelection, $router.selectedTab)
            }
            .tabItem {
                Label("Insights", systemImage: "chart.bar.fill")
            }
            .tag(2)
            .accessibilityIdentifier("Insights")
            
            // Settings Tab
            NavigationStack(path: $router.settingsStack) {
                SettingsView()
                    .navigationDestination(for: AppNavigationDestination.self) { destination in
                        destinationFactory.makeDestinationView(for: destination)
                    }
                    .withPerformanceDebugToggle()
                    .environment(\.tabSelection, $router.selectedTab)
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(3)
            .accessibilityIdentifier("Settings")
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
        .onAppear {
            // Configure app appearance
            AppearanceManager.shared.configureTabBarAppearance()
            
            // Check if we're running UI tests
            if ProcessInfo.processInfo.arguments.contains("UI_TESTING") {
                // Special setup for UI test mode
                AppearanceManager.shared.setupForUITesting()
            }
            
            // Start performance monitoring
            PerformanceMetrics.shared.startMonitoring()
        }
        .onChange(of: router.selectedTab) { oldValue, newValue in
            // When switching to the Payslips tab (index 1), trigger a data refresh
            if newValue == 1 && oldValue != 1 {
                // Use a small delay to ensure the tab has fully transitioned
                Task {
                    try? await Task.sleep(nanoseconds: 150_000_000) // 0.15 seconds
                    PayslipEvents.notifyForcedRefreshRequired()
                }
            }
        }
        .accessibilityIdentifier("main_tab_bar")
        .trackPerformance(name: "MainTabView")
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