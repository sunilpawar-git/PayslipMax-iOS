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

// Step 4: Add the views
struct ContentView: View {
    // Add the router as a StateObject
    @StateObject private var router = NavRouter()
    
    var body: some View {
        TabView {
            // Home Tab
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            // Payslips Tab
            NavigationStack {
                PayslipsView()
                    .navigationTitle("Payslips")
            }
            .tabItem {
                Label("Payslips", systemImage: "doc.text.fill")
            }
            
            // Insights Tab
            NavigationStack {
                InsightsView()
                    .navigationTitle("Insights")
            }
            .tabItem {
                Label("Insights", systemImage: "chart.bar.fill")
            }
            
            // Settings Tab
            NavigationStack {
                SettingsView()
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .environmentObject(router)
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
        ContentView()
            .modelContainer(previewContainer)
    }
    
    // Create a static preview container with the correct schema
    static var previewContainer: ModelContainer {
        do {
            // Create a schema with the models
            let schema = Schema([
                PayslipItem.self,
                Payslip.self,
                Deduction.self,
                PostingDetails.self,
                Item.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: config)
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}
