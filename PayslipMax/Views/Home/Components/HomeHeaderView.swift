import SwiftUI

/// The header view for the home screen with logo and action buttons
struct HomeHeaderView: View {
    let onUploadTapped: () -> Void
    let onScanTapped: () -> Void
    let onManualTapped: () -> Void
    
    var body: some View {
        ZStack {
            // Background that extends to top including status bar
            Color(red: 0, green: 0, blue: 0.5) // Navy blue color
                .edgesIgnoringSafeArea(.top)
            
            VStack(spacing: 60) {
                // App Logo and Name
                HStack {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                        .accessibilityIdentifier("home_header")
                    Text("Payslip Max")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                        .accessibilityIdentifier("home_header")
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                .accessibilityIdentifier("home_header")
                
                // Action Buttons
                ActionButtonsView(
                    onUploadTapped: onUploadTapped,
                    onScanTapped: onScanTapped,
                    onManualTapped: onManualTapped
                )
            }
        }
    }
}

#Preview {
    HomeHeaderView(
        onUploadTapped: {},
        onScanTapped: {},
        onManualTapped: {}
    )
} 