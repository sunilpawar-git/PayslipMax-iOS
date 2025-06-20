import SwiftUI

struct BackupSettingsView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingBackupSheet = false
    
    var body: some View {
        SettingsSection(title: "CLOUD BACKUP") {
            SettingsRow(
                icon: "icloud.and.arrow.up",
                iconColor: subscriptionManager.isPremiumUser ? FintechColors.primaryBlue : FintechColors.textSecondary,
                title: "Backup & Restore",
                subtitle: subscriptionManager.isPremiumUser ? "Export to any cloud service or import from backup" : "Pro feature - Secure cloud backup",
                action: {
                    showingBackupSheet = true
                }
            )
        }
        .sheet(isPresented: $showingBackupSheet) {
            BackupViewWrapper()
        }
    }
}

#Preview {
    BackupSettingsView()
} 