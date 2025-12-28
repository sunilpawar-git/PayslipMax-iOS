//
//  CropConfirmationView.swift
//  PayslipMax
//
//  Pre-send confirmation screen showing exactly what will be processed
//

import SwiftUI

/// Confirmation view that displays the cropped payslip before LLM processing
///
/// **Purpose**: Final privacy check to ensure no PII is visible in cropped area
///
/// **User Flow**:
/// 1. User adjusts crop in PayslipCropView
/// 2. Clicks "Preview Crop"
/// 3. This view displays with privacy checklist
/// 4. User confirms or goes back to re-crop
///
/// **Privacy Checklist**:
/// - No names visible
/// - No account numbers visible
/// - No PAN/Service number visible
/// - Only salary details visible
struct CropConfirmationView: View {
    let croppedImage: UIImage
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Title
                Text("⚠️ Final Privacy Check")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top, 8)

                // Subtitle
                Text("This is what will be sent for processing:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                // Image preview with border
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    Image(uiImage: croppedImage)
                        .resizable()
                        .scaledToFit()
                        .border(Color.red, width: 2)
                        .accessibilityIdentifier("cropped_image_preview")
                }
                .frame(maxHeight: 400)

                // Privacy checklist
                VStack(alignment: .leading, spacing: 12) {
                    PrivacyCheckItem(
                        icon: "person.fill.xmark",
                        text: "No names visible?",
                        color: .red
                    )
                    PrivacyCheckItem(
                        icon: "creditcard.fill",
                        text: "No account numbers visible?",
                        color: .orange
                    )
                    PrivacyCheckItem(
                        icon: "number",
                        text: "No PAN/Service number visible?",
                        color: .yellow
                    )
                    PrivacyCheckItem(
                        icon: "checkmark.circle.fill",
                        text: "Only salary details visible?",
                        color: .green
                    )
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                .accessibilityIdentifier("privacy_checklist")

                Spacer()

                // Action buttons
                HStack(spacing: 16) {
                    Button(action: onCancel) {
                        Text("Go Back & Re-crop")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("cancel_button")

                    Button(action: onConfirm) {
                        Text("Looks Good, Process")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .accessibilityIdentifier("confirm_button")
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("Confirm Cropped Area")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// Individual privacy checklist item
struct PrivacyCheckItem: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)

            Spacer()
        }
    }
}

// MARK: - Previews

#if DEBUG
struct CropConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample image for preview
        let sampleImage = UIImage(systemName: "doc.text.fill")!
            .withTintColor(.gray, renderingMode: .alwaysOriginal)

        CropConfirmationView(
            croppedImage: sampleImage,
            onCancel: {
                print("Cancel tapped")
            },
            onConfirm: {
                print("Confirm tapped")
            }
        )
    }
}
#endif
