import SwiftUI

/// Header view for web upload with registration controls
struct WebUploadHeaderView: View {
    let deviceRegistrationStatus: RegistrationStatus
    let isRegistering: Bool
    
    let onRegisterDevice: () -> Void
    let onShowQRCode: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Connect to Web")
                    .font(.headline)
                    .foregroundColor(FintechColors.textPrimary)
                Spacer()
                Button(action: onRegisterDevice) {
                    Text(registerButtonText)
                }
                .buttonStyle(.borderedProminent)
                .disabled(deviceRegistrationStatus == .registering)
                
                if deviceRegistrationStatus == .registered {
                    Button(action: onShowQRCode) {
                        Image(systemName: "qrcode")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal)
            
            if deviceRegistrationStatus == .registered {
                Text("Device connected to PayslipMax.com")
                    .font(.caption)
                    .foregroundColor(FintechColors.successGreen)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            } else {
                Text("Register your device to upload PDFs from PayslipMax.com directly to your app")
                    .font(.caption)
                    .foregroundColor(FintechColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(FintechColors.backgroundGray)
    }
    
    private var registerButtonText: String {
        switch deviceRegistrationStatus {
        case .notRegistered, .failed:
            return "Register"
        case .registering:
            return "Registering..."
        case .registered:
            return "Reconnect"
        }
    }
}

// MARK: - Preview
#if DEBUG
struct WebUploadHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            WebUploadHeaderView(
                deviceRegistrationStatus: .notRegistered,
                isRegistering: false,
                onRegisterDevice: {},
                onShowQRCode: {}
            )
            
            WebUploadHeaderView(
                deviceRegistrationStatus: .registered,
                isRegistering: false,
                onRegisterDevice: {},
                onShowQRCode: {}
            )
        }
    }
}
#endif
