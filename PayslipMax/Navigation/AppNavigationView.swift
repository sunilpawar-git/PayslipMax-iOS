import SwiftUI
import SwiftData
import PDFKit

struct AppNavigationView: View {
    @StateObject private var coordinator = AppCoordinator()
    @Environment(\.modelContext) private var modelContext
    private let destinationFactory: DestinationFactoryProtocol
    
    init(destinationFactory: DestinationFactoryProtocol? = nil) {
        self._coordinator = StateObject(wrappedValue: AppCoordinator())
        // Use provided factory or create default from DIContainer
        self.destinationFactory = destinationFactory ?? DIContainer.shared.makeDestinationFactory()
    }
    
    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            // Home Tab
            NavigationStack(path: $coordinator.path) {
                HomeView()
                    .navigationDestination(for: AppNavigationDestination.self) { destination in
                        destinationFactory.makeDestinationView(for: destination)
                    }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // Payslips Tab
            NavigationStack(path: $coordinator.path) {
                PayslipsView()
                    .navigationDestination(for: AppNavigationDestination.self) { destination in
                        destinationFactory.makeDestinationView(for: destination)
                    }
            }
            .tabItem {
                Label("Payslips", systemImage: "doc.text.fill")
            }
            .tag(1)
            
            // Insights Tab
            NavigationStack(path: $coordinator.path) {
                InsightsView()
                    .navigationDestination(for: AppNavigationDestination.self) { destination in
                        destinationFactory.makeDestinationView(for: destination)
                    }
            }
            .tabItem {
                Label("Insights", systemImage: "chart.bar.fill")
            }
            .tag(2)
            
            // Settings Tab
            NavigationStack(path: $coordinator.path) {
                SettingsView()
                    .navigationDestination(for: AppNavigationDestination.self) { destination in
                        destinationFactory.makeDestinationView(for: destination)
                    }
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(3)
        }
        .sheet(item: $coordinator.sheet) { destination in
            destinationFactory.makeModalView(
                for: destination,
                isSheet: true,
                onDismiss: { coordinator.dismissSheet() }
            )
        }
        .fullScreenCover(item: $coordinator.fullScreenCover) { destination in
            destinationFactory.makeModalView(
                for: destination,
                isSheet: false,
                onDismiss: { coordinator.dismissFullScreen() }
            )
        }
        .environmentObject(coordinator)
    }
} 