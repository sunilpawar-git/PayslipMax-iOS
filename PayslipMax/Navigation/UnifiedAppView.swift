import SwiftUI
import SwiftData

/// Unified app view that replaces both AppNavigationView and MainTabView
/// Uses the new NavigationCoordinator for clean, type-safe navigation
struct UnifiedAppView: View {
    @StateObject private var coordinator = NavigationCoordinator()
    @StateObject private var loadingManager = GlobalLoadingManager.shared
    @StateObject private var transitionCoordinator = TabTransitionCoordinator.shared
    
    @Environment(\.modelContext) private var modelContext
    
    private let destinationFactory: DestinationFactoryProtocol
    
    init(destinationFactory: DestinationFactoryProtocol? = nil) {
        // Use provided factory or create default from DIContainer
        self.destinationFactory = destinationFactory ?? DIContainer.shared.makeDestinationFactory()
    }
    
    var body: some View {
        ZStack {
            TabView(selection: $coordinator.selectedTab) {
                // Home Tab
                NavigationStack(path: $coordinator.homeStack) {
                    HomeView(viewModel: destinationFactory.makeHomeViewModel())
                        .navigationDestination(for: AppNavigationDestination.self) { destination in
                            destinationFactory.makeDestinationView(for: destination)
                        }
                        .withPerformanceDebugToggle()
                }
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
                .accessibilityIdentifier("Home")
                
                // Payslips Tab
                NavigationStack(path: $coordinator.payslipsStack) {
                    PayslipsView(viewModel: DIContainer.shared.makePayslipsViewModel())
                        .navigationDestination(for: AppNavigationDestination.self) { destination in
                            destinationFactory.makeDestinationView(for: destination)
                        }
                        .withPerformanceDebugToggle()
                }
                .tabItem {
                    Label("Payslips", systemImage: "doc.text.fill")
                }
                .tag(1)
                .accessibilityIdentifier("Payslips")
                
                // Insights Tab
                NavigationStack(path: $coordinator.insightsStack) {
                    InsightsView(coordinator: destinationFactory.makeInsightsCoordinator())
                        .navigationDestination(for: AppNavigationDestination.self) { destination in
                            destinationFactory.makeDestinationView(for: destination)
                        }
                        .withPerformanceDebugToggle()
                }
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }
                .tag(2)
                .accessibilityIdentifier("Insights")
                
                // Settings Tab
                NavigationStack(path: $coordinator.settingsStack) {
                    SettingsView(viewModel: destinationFactory.makeSettingsViewModel())
                        .navigationDestination(for: AppNavigationDestination.self) { destination in
                            destinationFactory.makeDestinationView(for: destination)
                        }
                        .withPerformanceDebugToggle()
                }
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
                .accessibilityIdentifier("Settings")
            }
            .animation(.easeInOut(duration: 0.25), value: coordinator.selectedTab)
            
            // Global overlay system
            GlobalOverlayContainer()
                .allowsHitTesting(loadingManager.isLoading || !GlobalOverlaySystem.shared.activeOverlays.isEmpty)
        }
        .sheet(item: $coordinator.sheet) { destination in
            destinationFactory.makeModalView(for: destination, isSheet: true) {
                coordinator.dismissSheet()
            }
        }
        .fullScreenCover(item: $coordinator.fullScreenCover) { destination in
            destinationFactory.makeModalView(for: destination, isSheet: false) {
                coordinator.dismissFullScreen()
            }
        }
        .environmentObject(coordinator)
        .onOpenURL { url in
            _ = coordinator.handleDeepLink(url)
        }
        .onChange(of: coordinator.selectedTab) { oldValue, newValue in
            // Sync with transition coordinator for backwards compatibility
            transitionCoordinator.selectedTab = newValue
        }
        .onReceive(transitionCoordinator.$selectedTab) { newTab in
            // Allow transition coordinator to still control tab selection
            if coordinator.selectedTab != newTab {
                coordinator.selectedTab = newTab
            }
        }
    }
}

#if DEBUG
struct UnifiedAppView_Previews: PreviewProvider {
    static var previews: some View {
        UnifiedAppView()
            .modelContainer(for: [PayslipItem.self], inMemory: true)
    }
}
#endif 