import SwiftUI

/// A container view for the three action buttons on the home screen
struct ActionButtonsView: View {
    let onUploadTapped: () -> Void
    let onScanTapped: () -> Void
    let onManualTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 50) {
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
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.white)
                    .accessibilityIdentifier(icon)
                
                Text(title)
                    .font(.callout)
                    .foregroundColor(.white)
                    .accessibilityIdentifier(accessibilityId ?? "")
            }
            .frame(width: 65, height: 75)
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