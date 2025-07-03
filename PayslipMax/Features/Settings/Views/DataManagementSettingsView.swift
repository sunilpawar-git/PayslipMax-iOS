import SwiftUI
import SwiftData

struct DataManagementSettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showingWebUploadSheet = false
    @State private var showingClearDataConfirmation = false
    
    init(viewModel: SettingsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        SettingsSection(title: "DATA MANAGEMENT") {
            VStack(spacing: 0) {
                // Manage Web Uploads
                SettingsRow(
                    icon: "icloud.and.arrow.down",
                    iconColor: FintechColors.chartSecondary,
                    title: "Manage Web Uploads",
                    subtitle: "PDFs uploaded from PayslipMax.com",
                    action: {
                        showingWebUploadSheet = true
                    }
                )
                
                FintechDivider()
                
                // Clear All Data
                SettingsRow(
                    icon: "trash.fill",
                    iconColor: FintechColors.dangerRed,
                    title: "Clear All Data",
                    subtitle: "Remove all payslips & relevant data",
                    action: {
                        showingClearDataConfirmation = true
                    }
                )
            }
        }
        .sheet(isPresented: $showingWebUploadSheet) {
            NavigationView {
                let webUploadViewModel = DIContainer.shared.makeWebUploadViewModel()
                WebUploadListView(viewModel: webUploadViewModel)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                showingWebUploadSheet = false
                            }
                        }
                    }
            }
        }
        .confirmationDialog(
            "Clear All Data",
            isPresented: $showingClearDataConfirmation,
            titleVisibility: .visible
        ) {
            Button("Yes", role: .destructive) {
                viewModel.clearAllData(context: modelContext)
            }
            Button("No", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete all payslips & relevant data from the app?")
        }
    }
}

#Preview {
    DataManagementSettingsView(viewModel: DIContainer.shared.makeSettingsViewModel())
} 