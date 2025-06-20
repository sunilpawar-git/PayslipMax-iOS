import SwiftUI
import SwiftData

struct DataManagementSettingsView: View {
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var showingWebUploadSheet = false
    
    init(viewModel: SettingsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // MARK: - Web Upload Section
            SettingsSection(title: "WEB UPLOAD") {
                SettingsRow(
                    icon: "icloud.and.arrow.down",
                    iconColor: FintechColors.chartSecondary,
                    title: "Manage Web Uploads",
                    subtitle: "PDFs uploaded from PayslipMax.com",
                    action: {
                        showingWebUploadSheet = true
                    }
                )
            }
            
            // MARK: - Data Management Section
            SettingsSection(title: "DATA MANAGEMENT") {
                SettingsRow(
                    icon: "trash.fill",
                    iconColor: FintechColors.dangerRed,
                    title: "Clear All Data",
                    subtitle: "Remove all payslips",
                    action: {
                        viewModel.clearAllData(context: modelContext)
                    }
                )
            }
        }
        .sheet(isPresented: $showingWebUploadSheet) {
            let webUploadViewModel = DIContainer.shared.makeWebUploadViewModel()
            WebUploadListView(viewModel: webUploadViewModel)
        }
    }
}

#Preview {
    DataManagementSettingsView(viewModel: DIContainer.shared.makeSettingsViewModel())
} 