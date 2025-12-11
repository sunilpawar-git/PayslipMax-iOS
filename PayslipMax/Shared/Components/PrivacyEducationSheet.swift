import SwiftUI

/// Privacy education bottom sheet shown to first-time users
struct PrivacyEducationSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(.top, 20)

            // Title
            Text("Privacy-First Scanning")
                .font(.title2.bold())

            // Steps
            VStack(alignment: .leading, spacing: 16) {
                stepRow(number: "1️⃣", title: "Select your payslip photo")
                stepRow(number: "2️⃣", title: "Crop out personal details", subtitle: "Name, Account, PAN")
                stepRow(number: "3️⃣", title: "AI processes salary data only")
            }
            .padding(.horizontal)

            // Trust message
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.green)
                Text("Your privacy is protected at every step")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)

            // Continue button
            Button {
                markAsShown()
                onContinue()
                dismiss()
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .padding(.vertical, 32)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func stepRow(number: String, title: String, subtitle: String? = nil) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
    }

    private func markAsShown() {
        UserDefaults.standard.set(true, forKey: "hasSeenPrivacyEducation")
    }
}

// MARK: - Privacy Education Helper

extension UserDefaults {
    static var hasSeenPrivacyEducation: Bool {
        UserDefaults.standard.bool(forKey: "hasSeenPrivacyEducation")
    }
}
