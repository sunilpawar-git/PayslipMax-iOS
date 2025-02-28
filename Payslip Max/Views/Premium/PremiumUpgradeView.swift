import SwiftUI

// Simple version of PremiumUpgradeView without ViewModel dependencies
struct PremiumUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerView
                    featuresView
                    upgradeButton
                }
                .padding()
            }
            .navigationTitle("Premium Features")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button("Dismiss") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 72))
                .foregroundColor(.yellow)
            
            Text("Upgrade to Premium")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Unlock powerful features to get the most out of your payslips")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding(.vertical)
    }
    
    private var featuresView: some View {
        VStack(spacing: 16) {
            Text("Premium Features")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Static features list
            FeatureRow(
                icon: "icloud",
                title: "Cloud Backup",
                description: "Securely store your payslips in the cloud"
            )
            
            FeatureRow(
                icon: "devices.homekit",
                title: "Cross-Device Sync",
                description: "Access your payslips on all your devices"
            )
            
            FeatureRow(
                icon: "chart.bar",
                title: "Advanced Analytics",
                description: "Get deeper insights into your finances"
            )
            
            FeatureRow(
                icon: "square.and.arrow.up",
                title: "Export Reports",
                description: "Export detailed reports in multiple formats"
            )
        }
    }
    
    private var upgradeButton: some View {
        Button {
            // Show coming soon message
            // In the future, this will be connected to the premium upgrade flow
        } label: {
            Text("Coming Soon")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.borderedProminent)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    PremiumUpgradeView()
} 