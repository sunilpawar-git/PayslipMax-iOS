import SwiftUI
import SwiftData
import PDFKit
import UIKit

/// Main tab view with navigation for the app
struct MainTabView: View {
    // Navigation router
    @StateObject private var router = NavRouter()
    
    var body: some View {
        TabView(selection: $router.selectedTab) {
            // Home Tab
            NavigationStack(path: $router.homeStack) {
                HomeView()
                    .navigationDestination(for: NavDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // Payslips Tab
            NavigationStack(path: $router.payslipsStack) {
                PayslipsView()
                    .navigationDestination(for: NavDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Label("Payslips", systemImage: "doc.text.fill")
            }
            .tag(1)
            
            // Insights Tab
            NavigationStack(path: $router.insightsStack) {
                InsightsView()
                    .navigationDestination(for: NavDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Label("Insights", systemImage: "chart.bar.fill")
            }
            .tag(2)
            
            // Settings Tab
            NavigationStack(path: $router.settingsStack) {
                SettingsView()
                    .navigationDestination(for: NavDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(3)
        }
        .sheet(item: $router.sheetDestination) { destination in
            modalView(for: destination, isSheet: true)
        }
        .fullScreenCover(item: $router.fullScreenDestination) { destination in
            modalView(for: destination, isSheet: false)
        }
        .environmentObject(router)
        .onAppear {
            // Set the tab bar appearance to use system background color
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithDefaultBackground()
            
            UITabBar.appearance().standardAppearance = tabBarAppearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            }
        }
    }
    
    /// Builds the appropriate view for a navigation destination
    @ViewBuilder
    private func destinationView(for destination: NavDestination) -> some View {
        switch destination {
        case .payslipDetail(let id):
            if let payslip = getPayslip(byId: id) {
                PayslipNavigation.detailView(for: payslip)
            } else {
                Text("Payslip not found")
                    .padding()
            }
        case .privacyPolicy:
            Text("Privacy Policy")
                .padding()
                .navigationTitle("Privacy Policy")
        case .termsOfService:
            Text("Terms of Service")
                .padding()
                .navigationTitle("Terms of Service")
        case .changePin:
            Text("Change PIN View")
                .padding()
                .navigationTitle("Change PIN")
        // Other cases should be handled as modals, not in the navigation stack
        default:
            Text("This should be presented as a modal")
                .padding()
        }
    }
    
    /// Builds the appropriate view for a modal presentation
    @ViewBuilder
    private func modalView(for destination: NavDestination, isSheet: Bool) -> some View {
        switch destination {
        case .pdfPreview(let document):
            PDFPreviewView(document: document)
        case .addPayslip:
            let isPresented = Binding<Bool>(
                get: { true },
                set: { if !$0 { router.dismissSheet() } }
            )
            AddPayslipSheet(isPresented: isPresented, pdfManager: PDFUploadManager())
        case .scanner:
            PayslipScannerView()
        case .privacyPolicy:
            NavigationView {
                Text("Privacy Policy Content")
                    .padding()
                    .navigationTitle("Privacy Policy")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                if isSheet {
                                    router.dismissSheet()
                                } else {
                                    router.dismissFullScreen()
                                }
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
                                if isSheet {
                                    router.dismissSheet()
                                } else {
                                    router.dismissFullScreen()
                                }
                            }
                        }
                    }
            }
        default:
            Text("Modal not implemented")
                .padding()
        }
    }
    
    /// Helper method to get a payslip by ID
    private func getPayslip(byId id: UUID) -> PayslipItem? {
        // In a real implementation, you would fetch this from your data store
        // This is just a placeholder
        return nil
    }
}

// MARK: - Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        // Simple preview with minimal dependencies
        MainTabView()
            .previewDisplayName("Default")
    }
} 