//
//  ContentView.swift
//  Payslip Max
//
//  Created by Sunil on 21/01/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var securityViewModel = DIContainer.shared.makeSecurityViewModel()
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            PayslipsView()
                .tabItem {
                    Label("Payslips", systemImage: "doc.text.fill")
                }
            
            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .modelContainer(previewContainer)
    }
    
    // Create a static preview container
    static var previewContainer: ModelContainer {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(
                for: PayslipItem.self,
                configurations: config
            )
            return container
        } catch {
            fatalError("Failed to create preview container")
        }
    }
}
