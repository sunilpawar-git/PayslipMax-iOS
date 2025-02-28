import SwiftUI

/// View model for the settings screen
class SettingsViewModel: ObservableObject {
    /// Security service for authentication
    private let securityService: SecurityServiceProtocol
    
    /// Data service for data operations
    private let dataService: DataServiceProtocol
    
    /// App theme
    @Published var theme = "System"
    
    /// Biometric authentication enabled
    @Published var biometricEnabled = true
    
    /// Cloud sync enabled
    @Published var cloudSyncEnabled = false
    
    /// Notification settings
    @Published var notificationsEnabled = true
    
    /// Initializes a new settings view model
    /// - Parameters:
    ///   - securityService: The security service
    ///   - dataService: The data service
    init(securityService: SecurityServiceProtocol, dataService: DataServiceProtocol) {
        self.securityService = securityService
        self.dataService = dataService
    }
    
    /// Toggles biometric authentication
    func toggleBiometric() {
        biometricEnabled.toggle()
        // In a real implementation, this would update the security service
    }
    
    /// Toggles cloud sync
    func toggleCloudSync() {
        cloudSyncEnabled.toggle()
        // In a real implementation, this would update the data service
    }
    
    /// Toggles notifications
    func toggleNotifications() {
        notificationsEnabled.toggle()
        // In a real implementation, this would update the notification settings
    }
    
    /// Changes the app theme
    /// - Parameter newTheme: The new theme
    func changeTheme(to newTheme: String) {
        theme = newTheme
        // In a real implementation, this would update the app theme
    }
}

/// Settings view displaying app settings
struct SettingsView: View {
    /// View model for the settings screen
    @ObservedObject var viewModel: SettingsViewModel
    
    /// Navigation router
    @EnvironmentObject private var router: NavRouter
    
    /// Available themes
    private let themes = ["System", "Light", "Dark"]
    
    var body: some View {
        List {
            // Appearance section
            Section(header: Text("Appearance")) {
                Picker("Theme", selection: $viewModel.theme) {
                    ForEach(themes, id: \.self) { theme in
                        Text(theme)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Security section
            Section(header: Text("Security")) {
                Toggle("Biometric Authentication", isOn: $viewModel.biometricEnabled)
                    .onChange(of: viewModel.biometricEnabled) { _ in
                        viewModel.toggleBiometric()
                    }
                
                Button("Change PIN") {
                    router.presentSheet(.changePin)
                }
            }
            
            // Sync section
            Section(header: Text("Sync")) {
                Toggle("Cloud Sync", isOn: $viewModel.cloudSyncEnabled)
                    .onChange(of: viewModel.cloudSyncEnabled) { _ in
                        viewModel.toggleCloudSync()
                    }
                
                if viewModel.cloudSyncEnabled {
                    Text("Last synced: Today, 2:30 PM")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Notifications section
            Section(header: Text("Notifications")) {
                Toggle("Enable Notifications", isOn: $viewModel.notificationsEnabled)
                    .onChange(of: viewModel.notificationsEnabled) { _ in
                        viewModel.toggleNotifications()
                    }
            }
            
            // About section
            Section(header: Text("About")) {
                Button("Privacy Policy") {
                    router.presentSheet(.privacyPolicy)
                }
                
                Button("Terms of Service") {
                    router.presentSheet(.termsOfService)
                }
                
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            }
            
            // Support section
            Section(header: Text("Support")) {
                Button("Contact Support") {
                    // In a real implementation, this would open a support form or email
                    if let url = URL(string: "mailto:support@payslipmax.com") {
                        #if os(iOS)
                        UIApplication.shared.open(url)
                        #elseif os(macOS)
                        NSWorkspace.shared.open(url)
                        #endif
                    }
                }
                
                Button("Rate the App") {
                    // In a real implementation, this would open the app store page
                }
            }
            
            // Danger zone
            Section {
                Button("Clear All Data") {
                    // In a real implementation, this would show a confirmation dialog
                }
                .foregroundColor(.red)
            } header: {
                Text("Danger Zone")
            } footer: {
                Text("This will permanently delete all your data and cannot be undone.")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: SettingsViewModel(
            securityService: MockSecurityService(),
            dataService: MockDataService()
        ))
        .environmentObject(NavRouter())
    }
}

/// Mock security service for previews
class MockSecurityService: SecurityServiceProtocol {
    var isInitialized: Bool = true
    
    func initialize() async throws {
        // No-op for mock
    }
    
    func encrypt(_ data: Data) async throws -> Data {
        return data
    }
    
    func decrypt(_ data: Data) async throws -> Data {
        return data
    }
    
    func authenticate() async throws -> Bool {
        return true
    }
} 