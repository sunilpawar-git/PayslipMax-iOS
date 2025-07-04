import SwiftUI

struct AboutSettingsView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    
    var body: some View {
        SettingsSection(title: "ABOUT") {
            VStack(spacing: 0) {
                SettingsInfoRow(
                    icon: "info.circle.fill",
                    iconColor: FintechColors.textSecondary,
                    title: "Version",
                    value: "1.0.0"
                )
                
                FintechDivider()
                
                SettingsRow(
                    icon: "doc.text.fill",
                    iconColor: FintechColors.textSecondary,
                    title: "Privacy Policy",
                    subtitle: "View our privacy policy",
                    action: {
                        coordinator.presentSheet(.privacyPolicy)
                    }
                )
            }
        }
    }
}

#Preview {
    AboutSettingsView()
        .environmentObject(AppCoordinator())
} 