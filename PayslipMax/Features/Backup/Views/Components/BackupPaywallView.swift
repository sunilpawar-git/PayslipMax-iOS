import SwiftUI

/// Premium paywall interface for backup functionality
struct BackupPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingPaywall = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Icon and Header
            headerSection
            
            // Features List
            featuresSection
            
            // CTA Buttons
            ctaButtons
            
            Spacer()
        }
        .padding()
        .background(FintechColors.appBackground)
        .sheet(isPresented: $showingPaywall) {
            PremiumPaywallView()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [FintechColors.primaryBlue.opacity(0.2), FintechColors.primaryBlue.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: "icloud.and.arrow.up")
                    .font(.system(size: 40))
                    .foregroundColor(FintechColors.primaryBlue)
            }
            
            VStack(spacing: 12) {
                Text("Backup & Restore")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(FintechColors.textPrimary)
                
                Text("Secure cloud backup is a Pro feature")
                    .font(.subheadline)
                    .foregroundColor(FintechColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(spacing: 16) {
            ProFeatureRow(
                icon: "shield.checkered",
                title: "Encrypted Backups",
                description: "Your data is encrypted and secure"
            )
            
            ProFeatureRow(
                icon: "icloud",
                title: "Cloud Storage",
                description: "Save to any cloud service you prefer"
            )
            
            ProFeatureRow(
                icon: "arrow.triangle.2.circlepath",
                title: "Easy Device Transfer",
                description: "Seamlessly move data between devices"
            )
            
            ProFeatureRow(
                icon: "checkmark.seal",
                title: "Data Integrity",
                description: "Checksums ensure your data is intact"
            )
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - CTA Buttons
    
    private var ctaButtons: some View {
        VStack(spacing: 12) {
            Button(action: { showingPaywall = true }) {
                HStack {
                    Image(systemName: "crown.fill")
                    Text("Upgrade to Pro - ₹99/Year")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [FintechColors.primaryBlue, FintechColors.primaryBlue.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            
            Button("Close") {
                dismiss()
            }
            .foregroundColor(FintechColors.textSecondary)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Supporting Views

struct ProFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(FintechColors.primaryBlue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(FintechColors.textPrimary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(FintechColors.textSecondary)
            }
            
            Spacer()
        }
    }
} 