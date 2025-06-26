import SwiftUI

/// Supporting views for backup functionality
struct BackupHeaderView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "icloud.and.arrow.up")
                .font(.system(size: 40))
                .foregroundColor(FintechColors.primaryBlue)
            
            Text("Cloud Backup")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(FintechColors.textPrimary)
            
            Text("Export your data to any cloud service and restore it on any device")
                .font(.subheadline)
                .foregroundColor(FintechColors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}

/// Pro feature information component
struct BackupProFeatureInfo: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "crown.fill")
                    .foregroundColor(FintechColors.warningAmber)
                
                Text("Pro Feature")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(FintechColors.textPrimary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• Backup works with ANY cloud service")
                Text("• Secure encryption protects your data")
                Text("• Easy device switching and data migration")
                Text("• Works offline - no internet required for parsing")
            }
            .font(.subheadline)
            .foregroundColor(FintechColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(FintechColors.warningAmber.opacity(0.1))
        .cornerRadius(12)
    }
}

/// Error view for backup service initialization failures
struct BackupErrorView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(FintechColors.dangerRed)
            
            Text("Service Unavailable")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(FintechColors.textPrimary)
            
            Text("Backup service could not be initialized. Please try again later.")
                .font(.subheadline)
                .foregroundColor(FintechColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(FintechColors.appBackground)
    }
} 