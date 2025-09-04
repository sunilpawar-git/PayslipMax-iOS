import SwiftUI

/// Loading state view for web uploads
struct WebUploadLoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .tint(FintechColors.primaryBlue)
            Text("Loading uploads...")
                .foregroundColor(FintechColors.textSecondary)
                .padding(.top)
            Spacer()
        }
    }
}

/// Empty state view for web uploads
struct WebUploadEmptyStateView: View {
    let deviceRegistrationStatus: RegistrationStatus
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "icloud.and.arrow.down")
                .font(.system(size: 60))
                .foregroundColor(FintechColors.textSecondary)
            
            VStack(spacing: 8) {
                Text("No Web Uploads")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(FintechColors.textPrimary)
                
                Text("Upload PDFs from PayslipMax.com to see them here")
                    .font(.body)
                    .foregroundColor(FintechColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if deviceRegistrationStatus != .registered {
                Text("Make sure your device is registered to receive uploads")
                    .font(.caption)
                    .foregroundColor(FintechColors.warningAmber)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview
#if DEBUG
struct WebUploadStateViews_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            WebUploadLoadingView()
            
            Divider()
            
            WebUploadEmptyStateView(deviceRegistrationStatus: .notRegistered)
        }
    }
}
#endif
