//
//  ContentView.swift
//  Payslip Max
//
//  Created by Sunil on 21/01/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    // State for demo purposes
    @State private var selectedTab = 0
    @State private var isBackupInProgress = false
    @State private var backupStatus = "No backup started"
    @State private var isPremiumUser = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab with network demo
            VStack(spacing: 20) {
                Text("Network Features Demo")
                    .font(.title)
                    .padding()
                
                Toggle("Premium User", isOn: $isPremiumUser)
                    .padding()
                    .frame(width: 200)
                
                Button("Test Cloud Backup") {
                    performBackup()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isBackupInProgress)
                
                if isBackupInProgress {
                    ProgressView()
                        .padding()
                }
                
                Text(backupStatus)
                    .padding()
                    .multilineTextAlignment(.center)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            // Other tabs
            Text("Payslips")
                .tabItem {
                    Label("Payslips", systemImage: "doc.text.fill")
                }
                .tag(1)
            
            Text("Insights")
                .tabItem {
                    Label("Insights", systemImage: "chart.bar.fill")
                }
                .tag(2)
            
            Text("Settings")
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }
    
    // Demo function to test cloud backup
    private func performBackup() {
        isBackupInProgress = true
        backupStatus = "Starting backup..."
        
        // Simulate network operation with premium check
        Task {
            do {
                // Check if user is premium
                if !isPremiumUser {
                    throw DemoError.premiumFeatureUnavailable
                }
                
                // Simulate network delay
                try await Task.sleep(nanoseconds: 2_000_000_000)
                
                // Update UI on main thread
                await MainActor.run {
                    backupStatus = "Backup completed successfully!"
                    isBackupInProgress = false
                }
            } catch let error as DemoError {
                await MainActor.run {
                    backupStatus = "Backup failed: \(error.localizedDescription)"
                    isBackupInProgress = false
                }
            } catch {
                await MainActor.run {
                    backupStatus = "Backup failed: Unknown error"
                    isBackupInProgress = false
                }
            }
        }
    }
}

// Renamed to DemoError to avoid conflicts with the existing NetworkError
enum DemoError: LocalizedError {
    case premiumFeatureUnavailable
    case networkUnavailable
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .premiumFeatureUnavailable:
            return "This feature requires a premium subscription"
        case .networkUnavailable:
            return "Network connection unavailable"
        case .serverError:
            return "Server error occurred"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
} 