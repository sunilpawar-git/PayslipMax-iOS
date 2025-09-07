import SwiftUI

/// Main coordinator for backup functionality
struct BackupCoordinator: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = DIContainer.shared.makeSubscriptionManager()
    @StateObject private var qrCodeService = QRCodeService()
    
    @State private var backupService: BackupService?
    @State private var serviceInitializationFailed = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        Group {
            if let backupService = backupService {
                // Service initialized successfully
                if subscriptionManager.isPremiumUser {
                    BackupMainView(backupService: backupService, onError: handleError, onSuccess: handleSuccess)
                } else {
                    BackupPaywallView()
                }
            } else if serviceInitializationFailed {
                // Service initialization failed
                BackupErrorView()
            } else {
                // Service initializing
                BackupServiceInitializer(
                    onServiceCreated: { service in
                        backupService = service
                    },
                    onError: {
                        serviceInitializationFailed = true
                    }
                )
            }
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("OK") { }
        } message: {
            Text(successMessage)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    private func handleSuccess() {
        showingSuccess = true
    }
    
    private var successMessage: String {
        return "Operation completed successfully!"
    }
}

/// Main backup view that contains export and import components
struct BackupMainView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var backupService: BackupService
    
    let onError: (String) -> Void
    let onSuccess: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                FintechColors.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        BackupHeaderView()
                        
                        // Export Section
                        BackupExportView(
                            backupService: backupService,
                            onError: onError,
                            onSuccess: onSuccess
                        )
                        
                        // Import Section
                        BackupImportView(
                            backupService: backupService,
                            onError: onError,
                            onSuccess: onSuccess
                        )
                        
                        // Pro Feature Info
                        BackupProFeatureInfo()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Backup & Restore")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button("Close") {
                    dismiss()
                }
            )
        }
    }
} 