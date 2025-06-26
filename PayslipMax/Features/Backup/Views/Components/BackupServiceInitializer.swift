import SwiftUI
import SwiftData

/// Service initialization component for backup functionality
struct BackupServiceInitializer: View {
    @Environment(\.modelContext) private var modelContext
    let onServiceCreated: (BackupService) -> Void
    let onError: () -> Void
    
    @State private var isInitializing = true
    
    var body: some View {
        Group {
            if isInitializing {
                loadingView
            }
        }
        .task {
            await initializeBackupService()
        }
    }
    
    // MARK: - Service Initialization
    
    @MainActor
    private func initializeBackupService() async {
        do {
            // Create dependencies manually
            let securityService = SecurityServiceImpl()
            try await securityService.initialize()
            
            let dataService = DataServiceImpl(securityService: securityService, modelContext: modelContext)
            try await dataService.initialize()
            
            let secureDataManager = SecureDataManager()
            
            // Create backup service
            let service = BackupService(
                dataService: dataService,
                secureDataManager: secureDataManager,
                modelContext: modelContext
            )
            
            isInitializing = false
            onServiceCreated(service)
        } catch {
            print("Failed to create BackupService: \(error)")
            isInitializing = false
            onError()
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Initializing Backup Service...")
                .font(.subheadline)
                .foregroundColor(FintechColors.textSecondary)
        }
        .padding()
        .background(FintechColors.appBackground)
    }
} 