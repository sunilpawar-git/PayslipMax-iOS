import SwiftUI

struct SubscriptionSettingsView: View {
    @StateObject private var subscriptionManager = DIContainer.shared.makeSubscriptionManager()
    @State private var showingSubscriptionSheet = false

    var body: some View {
        SettingsSection(title: "SUBSCRIPTION") {
            SettingsRow(
                icon: subscriptionManager.isPremiumUser ? "crown.fill" : "crown",
                iconColor: subscriptionManager.isPremiumUser ? FintechColors.warningAmber : FintechColors.textSecondary,
                title: subscriptionManager.isPremiumUser ? "PayslipMax Pro" : "Go Pro - ₹99/Year",
                subtitle: subscriptionManager.isPremiumUser ? "Active subscription" : "Cloud backup & cross-device sync",
                action: {
                    showingSubscriptionSheet = true
                }
            )
        }
        .sheet(isPresented: $showingSubscriptionSheet) {
            PremiumPaywallView(subscriptionManager: subscriptionManager)
        }
    }
}

// PremiumPaywallView is imported from Views/Subscription/PremiumPaywallView.swift

#Preview {
    SubscriptionSettingsView()
}
