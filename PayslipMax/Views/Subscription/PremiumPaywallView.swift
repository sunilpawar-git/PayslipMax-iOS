import SwiftUI

/// Simplified Premium Paywall View (temporarily simplified for build stability)
struct PremiumPaywallView: View {
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingPurchaseLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 12) {
                    Text("🚀 Upgrade to Pro")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Unlock premium features and insights")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Features list
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "chart.bar.fill", title: "Advanced Charts", description: "Detailed visualizations")
                    FeatureRow(icon: "doc.text.fill", title: "Custom Reports", description: "Export your data")
                    FeatureRow(icon: "headphones", title: "Priority Support", description: "Get help faster")
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Pricing
                if let tier = subscriptionManager.availableSubscriptions.first {
                    VStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text(subscriptionManager.formattedPrice(for: tier))
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Billed annually")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: {
                            purchaseSubscription(tier)
                        }) {
                            Text("Start Free Trial")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .disabled(showingPurchaseLoading)
                        
                        Button("Restore Purchases") {
                            Task {
                                try? await subscriptionManager.restorePurchases()
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func purchaseSubscription(_ tier: SubscriptionTier) {
        showingPurchaseLoading = true
        Task {
            do {
                try await subscriptionManager.subscribeTo(tier)
                dismiss()
            } catch {
                // Handle error
            }
            showingPurchaseLoading = false
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

struct PremiumPaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumPaywallView()
    }
}