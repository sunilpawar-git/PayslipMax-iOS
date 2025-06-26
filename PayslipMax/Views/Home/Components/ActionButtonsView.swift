import SwiftUI

/// A container view for the three action buttons on the home screen
struct ActionButtonsView: View {
    let onUploadTapped: () -> Void
    let onScanTapped: () -> Void
    let onManualTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 40) {
            // Upload Button
            ActionButton(
                icon: "arrow.up.doc.fill",
                title: "Upload",
                action: onUploadTapped,
                accessibilityId: "action_buttons"
            )
            
            // Scan Button
            ActionButton(
                icon: "doc.text.viewfinder",
                title: "Scan",
                action: onScanTapped,
                accessibilityId: "action_buttons"
            )
            
            // Manual Button
            ActionButton(
                icon: "square.and.pencil",
                title: "Manual",
                action: onManualTapped,
                accessibilityId: "action_buttons"
            )
        }
        .padding(.bottom, 40)
        .accessibilityIdentifier("action_buttons")
    }
}

/// A single action button with an icon and title
struct ActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    var accessibilityId: String? = nil
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    // Larger background circle with accent light blue color
                    Circle()
                        .fill(FintechColors.accentLightBlue.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(FintechColors.accentLightBlue.opacity(0.4), lineWidth: 2)
                        )
                    
                    // Icon centered in the circle
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                        .accessibilityIdentifier(icon)
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .accessibilityIdentifier(accessibilityId ?? "")
            }
            .frame(width: 85, height: 105)
        }
        .accessibilityIdentifier(accessibilityId ?? "action_buttons")
    }
}

#Preview {
    ZStack {
        Color.blue
        ActionButtonsView(
            onUploadTapped: {},
            onScanTapped: {},
            onManualTapped: {}
        )
    }
} 
