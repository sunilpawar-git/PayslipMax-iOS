import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    @AppStorage("useBiometrics") private var useBiometrics = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @State private var showingPrivacyPolicy = false
    @State private var showingTerms = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Security") {
                    Toggle("Use Biometric Authentication", isOn: $useBiometrics)
                    NavigationLink("Change PIN") {
                        Text("PIN Change View") // To be implemented
                    }
                }
                
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                }
                
                Section("Data Management") {
                    Button("Export Data") {
                        // To be implemented
                    }
                    Button("Backup Data") {
                        // To be implemented
                    }
                }
                
                Section("Legal") {
                    Button("Privacy Policy") {
                        showingPrivacyPolicy = true
                    }
                    Button("Terms of Service") {
                        showingTerms = true
                    }
                }
                
                Section("About") {
                    LabeledContent("Version", value: AppConstants.appVersion)
                    Button("Rate App") {
                        // To be implemented
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPrivacyPolicy) {
                Text("Privacy Policy") // To be implemented
            }
            .sheet(isPresented: $showingTerms) {
                Text("Terms of Service") // To be implemented
            }
        }
    }
}

#Preview {
    SettingsView()
} 