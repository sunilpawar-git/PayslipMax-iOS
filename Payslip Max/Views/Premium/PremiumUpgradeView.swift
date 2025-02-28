import SwiftUI

// Import the PremiumFeatureManager
struct PremiumUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Upgrade to Premium")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Get access to cloud backup, cross-device sync, and more!")
                .multilineTextAlignment(.center)
                .padding()
            
            // Feature list
            VStack(alignment: .leading, spacing: 15) {
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
            .padding()
            
            // Coming soon label
            Text("Coming Soon")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding()
            
            Button("Dismiss") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct PremiumUpgradeView_Previews: PreviewProvider {
    static var previews: some View {
        PremiumUpgradeView()
    }
} 