import SwiftUI
import SwiftData

struct SettingsCoordinator: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.modelContext) private var modelContext
    
    init(viewModel: SettingsViewModel? = nil) {
        // Use provided viewModel or create one from DIContainer
        let model = viewModel ?? DIContainer.shared.makeSettingsViewModel()
        self._viewModel = StateObject(wrappedValue: model)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Subscription Management
                    SubscriptionSettingsView()
                    
                    // MARK: - Cloud Backup
                    BackupSettingsView()
                    
                    // MARK: - User Preferences
                    PreferencesSettingsView(viewModel: viewModel)
                    
                    // MARK: - Data & Web Upload
                    DataManagementSettingsView(viewModel: viewModel)
                    
                    // MARK: - Support & FAQ
                    SupportSettingsView(viewModel: viewModel)
                    
                    // MARK: - App Information
                    AboutSettingsView()
                    
                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .background(FintechColors.appBackground)
            .navigationTitle("Settings")
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(FintechColors.textSecondary.opacity(0.1))
                }
            }
        }
        .onAppear {
            // Only load payslips if we need to - this avoids unnecessary data fetching
            if viewModel.payslips.isEmpty && !viewModel.isLoading {
                viewModel.loadPayslips(context: modelContext)
            }
        }
    }
}

#Preview {
    SettingsCoordinator()
} 