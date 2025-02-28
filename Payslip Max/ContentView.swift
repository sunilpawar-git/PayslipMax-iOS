// Step 1: Add the NavRouter
//
//  ContentView.swift
//  Payslip Max
//
//  Created by Sunil on 21/01/25.
//

import SwiftUI
import SwiftData
import Foundation
import PDFKit

// Step 4: Add the views
struct ContentView: View {
    // Add the router as a StateObject
    @StateObject private var router = NavRouter()
    
    // Add the DIContainer
    private let container = DIContainer.shared
    
    // Create view models
    private var homeViewModel: HomeViewModel { container.makeHomeViewModel() }
    private var payslipsViewModel: PayslipsViewModel { container.makePayslipsViewModel() }
    private var insightsViewModel: InsightsViewModel { container.makeInsightsViewModel() }
    private var settingsViewModel: SettingsViewModel { container.makeSettingsViewModel() }
    
    var body: some View {
        TabView(selection: $router.selectedTab) {
            // Home Tab
            NavigationStack(path: $router.homeStack) {
                HomeView(viewModel: homeViewModel)
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
                PayslipsView(viewModel: payslipsViewModel)
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
                InsightsView(viewModel: insightsViewModel)
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
                SettingsView(viewModel: settingsViewModel)
                    .navigationDestination(for: NavDestination.self) { destination in
                        destinationView(for: destination)
                    }
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(3)
        }
        .environmentObject(router)
        .sheet(item: $router.sheetDestination) { destination in
            destinationView(for: destination)
        }
        .fullScreenCover(item: $router.fullScreenDestination) { destination in
            destinationView(for: destination)
        }
    }
    
    // Helper method to create views for destinations
    @ViewBuilder
    private func destinationView(for destination: NavDestination) -> some View {
        switch destination {
        case .home:
            HomeView(viewModel: homeViewModel)
        case .payslips:
            PayslipsView(viewModel: payslipsViewModel)
        case .insights:
            InsightsView(viewModel: insightsViewModel)
        case .settings:
            SettingsView(viewModel: settingsViewModel)
        case .payslipDetail(let id):
            // We need to fetch the payslip by ID
            Text("Payslip Detail \(id)")
            // In a real implementation, you would fetch the payslip and create the view model
            // let payslip = fetchPayslip(id)
            // PayslipDetailView(viewModel: container.makePayslipDetailViewModel(for: payslip))
        case .pdfPreview(let document):
            PDFPreviewView(document: document)
        case .privacyPolicy:
            PrivacyPolicyView()
        case .termsOfService:
            TermsOfServiceView()
        case .changePin:
            ChangePinView(viewModel: SecurityViewModel())
        case .addPayslip:
            AddPayslipView()
        case .scanner:
            ScannerView()
        }
    }
}

// MARK: - DI Implementation Plan
/*
 To properly implement DI in this ContentView, we need to follow these steps:
 
 1. Fix the import issues:
    - Ensure NavRouter is accessible
    - Ensure DIContainer is accessible
    - Ensure model types (Payslip, etc.) are accessible
 
 2. Add the router:
    @StateObject private var router = NavRouter()
 
 3. Add the DIContainer:
    private let container = DIContainer.shared
 
 4. Use the container to create view models:
    let homeViewModel = container.makeHomeViewModel()
    let payslipsViewModel = container.makePayslipsViewModel()
    let insightsViewModel = container.makeInsightsViewModel()
    let settingsViewModel = container.makeSettingsViewModel()
 
 5. Pass the view models to the views:
    HomeView(viewModel: homeViewModel)
    PayslipsView(viewModel: payslipsViewModel)
    InsightsView(viewModel: insightsViewModel)
    SettingsView(viewModel: settingsViewModel)
 
 6. Add the router as an environment object:
    .environmentObject(router)
 
 7. Update the preview to use a test container:
    let testContainer = DIContainer.forTesting()
    ContentView()
        .modelContainer(previewContainer)
        .environmentObject(testContainer)
 
 8. Update the preview container with the correct models:
    let schema = Schema([
        Payslip.self,
        Allowance.self,
        Deduction.self,
        PostingDetails.self,
        PayslipItem.self
    ])
 */

// Step 5: Update the preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let testContainer = DIContainer.forTesting()
        
        ContentView()
            .modelContainer(previewContainer)
    }
    
    // Create a static preview container with an empty schema
    static var previewContainer: ModelContainer {
        do {
            // Create a schema with the models
            let schema = Schema([
                PayslipItem.self
                // Add other models as needed
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: config)
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}
