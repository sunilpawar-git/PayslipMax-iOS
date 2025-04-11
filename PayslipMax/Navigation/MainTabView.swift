import SwiftUI
import SwiftData
import PDFKit
import UIKit

/// Main tab view with navigation for the app
struct MainTabView: View {
    // Navigation router
    @StateObject private var router = NavRouter()
    
    // Destination factory for creating views
    private let destinationFactory: DestinationFactory
    
    // Default parameterless initializer 
    init() {
        self.destinationFactory = DestinationFactory(
            dataService: DIContainer.shared.dataService,
            pdfManager: PDFUploadManager()
        )
    }
    
    // Initializer with explicit factory parameter
    init(factory: DestinationFactory) {
        self.destinationFactory = factory
    }
    
    var body: some View {
        TabView(selection: $router.selectedTab) {
            // Home Tab
            NavigationStack(path: $router.homeStack) {
                HomeView()
                    .navigationDestination(for: NavDestination.self) { destination in
                        destinationFactory.makeDestinationView(for: destination)
                    }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            .accessibilityIdentifier("Home")
            
            // Payslips Tab
            NavigationStack(path: $router.payslipsStack) {
                PayslipsView()
                    .navigationDestination(for: NavDestination.self) { destination in
                        destinationFactory.makeDestinationView(for: destination)
                    }
            }
            .tabItem {
                Label("Payslips", systemImage: "doc.text.fill")
            }
            .tag(1)
            .accessibilityIdentifier("Payslips")
            
            // Insights Tab
            NavigationStack(path: $router.insightsStack) {
                InsightsView()
                    .navigationDestination(for: NavDestination.self) { destination in
                        destinationFactory.makeDestinationView(for: destination)
                    }
            }
            .tabItem {
                Label("Insights", systemImage: "chart.bar.fill")
            }
            .tag(2)
            .accessibilityIdentifier("Insights")
            
            // Settings Tab
            NavigationStack(path: $router.settingsStack) {
                SettingsView()
                    .navigationDestination(for: NavDestination.self) { destination in
                        destinationFactory.makeDestinationView(for: destination)
                    }
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
            // Check if we're running UI tests
            if ProcessInfo.processInfo.arguments.contains("UI_TESTING") {
                // Special setup for UI test mode
                setupForUITesting()
            }
            
            // Set the tab bar appearance to use system background color
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithDefaultBackground()
            
            UITabBar.appearance().standardAppearance = tabBarAppearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
        }
        .accessibilityIdentifier("main_tab_bar")
    }
    
    /// Sets up special configurations for UI testing
    private func setupForUITesting() {
        // Ensure tab bar buttons are accessible
        UITabBar.appearance().isAccessibilityElement = true
        
        // Make tab bar items more discoverable
        for item in UITabBar.appearance().items ?? [] {
            item.isAccessibilityElement = true
            if let title = item.title {
                item.accessibilityLabel = title
                item.accessibilityIdentifier = title
            }
        }
        
        // Additional setup for UI tests
        print("Setting up for UI testing mode")
    }
}

// MARK: - Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        // Simple preview with minimal dependencies
        // Create a mock DataService for the preview
        let mockDataService = DIContainer.shared.dataService
        let mockPDFManager = PDFUploadManager()
        
        MainTabView(factory: DestinationFactory(
            dataService: mockDataService,
            pdfManager: mockPDFManager
        ))
        .previewDisplayName("Default")
    }
} 