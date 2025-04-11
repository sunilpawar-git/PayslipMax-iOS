import SwiftUI
import SwiftData
import PDFKit

struct AppNavigationView: View {
    @StateObject private var coordinator = AppCoordinator()
    @Environment(\.modelContext) private var modelContext
    
    // We'll keep local view creation since AppNavigationView uses AppDestination,
    // but we'll note that this should be refactored in a future step to use
    // the same NavDestination type as MainTabView to fully leverage DestinationFactory
    
    var body: some View {
        TabView(selection: $coordinator.selectedTab) {
            // Home Tab
            NavigationStack(path: $coordinator.path) {
                HomeView()
                    .navigationDestination(for: AppDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // Payslips Tab
            NavigationStack(path: $coordinator.path) {
                PayslipsView()
                    .navigationDestination(for: AppDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Label("Payslips", systemImage: "doc.text.fill")
            }
            .tag(1)
            
            // Insights Tab
            NavigationStack(path: $coordinator.path) {
                InsightsView()
                    .navigationDestination(for: AppDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Label("Insights", systemImage: "chart.bar.fill")
            }
            .tag(2)
            
            // Settings Tab
            NavigationStack(path: $coordinator.path) {
                SettingsView()
                    .navigationDestination(for: AppDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(3)
        }
        .sheet(item: $coordinator.sheet) { destination in
            sheetView(for: destination)
        }
        .fullScreenCover(item: $coordinator.fullScreenCover) { destination in
            fullScreenView(for: destination)
        }
        .environmentObject(coordinator)
    }
    
    // MARK: - Helper methods for navigation destinations
    
    // TODO: In a future refactoring step, unify AppDestination and NavDestination,
    // then use DestinationFactory here instead of local view creation methods
    
    @ViewBuilder
    private func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .home:
            HomeView()
        case .payslips:
            PayslipsView()
        case .payslipDetail(let payslip):
            PayslipNavigation.detailView(for: payslip)
        case .insights:
            InsightsView()
        case .settings:
            SettingsView()
        case .addPayslip, .pinSetup, .scanner, .pdfPreview, .privacyPolicy, .termsOfService, .changePin:
            // These are modal destinations and shouldn't be pushed onto the stack
            Text("This destination should be presented modally")
                .padding()
        }
    }
    
    @ViewBuilder
    private func sheetView(for destination: AppDestination) -> some View {
        switch destination {
        case .addPayslip:
            AddPayslipSheet(
                isPresented: Binding(
                    get: { true },
                    set: { if !$0 { coordinator.dismissSheet() } }
                ),
                pdfManager: PDFUploadManager()
            )
        case .pinSetup:
            PINSetupView(
                isPresented: Binding(
                    get: { true },
                    set: { if !$0 { coordinator.dismissSheet() } }
                )
            )
        case .pdfPreview(let document):
            PDFPreviewView(
                document: document,
                onConfirm: {
                    // Handle confirmation if needed
                }
            )
        case .privacyPolicy:
            NavigationView {
                Text("Privacy Policy Content")
                    .padding()
                    .navigationTitle("Privacy Policy")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                coordinator.dismissSheet()
                            }
                        }
                    }
            }
        case .termsOfService:
            NavigationView {
                Text("Terms of Service Content")
                    .padding()
                    .navigationTitle("Terms of Service")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                coordinator.dismissSheet()
                            }
                        }
                    }
            }
        case .changePin:
            Text("Change PIN View")
                .padding()
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func fullScreenView(for destination: AppDestination) -> some View {
        switch destination {
        case .scanner:
            PayslipScannerView()
        default:
            EmptyView()
        }
    }
} 