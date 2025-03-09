import SwiftUI
import CoreImage.CIFilterBuiltins

/// A view that generates QR codes for deep links
struct DeepLinkQRView: View {
    @State private var selectedDeepLink = 0
    @State private var payslipId = UUID().uuidString
    @State private var qrImage = Image(systemName: "qrcode")
    
    private let deepLinks = [
        "Home": "/home",
        "Payslips": "/payslips",
        "Insights": "/insights",
        "Settings": "/settings",
        "Privacy Policy": "/privacy",
        "Terms of Service": "/terms",
        "Payslip Detail": "/payslip" // This one will use the payslipId
    ]
    
    var body: some View {
        Form {
            Section(header: Text("Deep Link")) {
                Picker("Select Deep Link", selection: $selectedDeepLink) {
                    ForEach(0..<deepLinks.count, id: \.self) { index in
                        Text(Array(deepLinks.keys)[index])
                    }
                }
                .onChange(of: selectedDeepLink) {
                    generateQRCode()
                }
                
                if Array(deepLinks.keys)[selectedDeepLink] == "Payslip Detail" {
                    TextField("Payslip ID", text: $payslipId)
                        .onChange(of: payslipId) {
                            generateQRCode()
                        }
                }
            }
            
            Section(header: Text("QR Code")) {
                HStack {
                    Spacer()
                    qrImage
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                    Spacer()
                }
                
                Text("Generated URL:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(generateDeepLinkURL())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            
            Section(header: Text("Usage")) {
                Text("You can use this QR code to open the app directly to the selected deep link. Scan it with a QR code scanner on an iOS device.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Deep Link QR Generator")
        .onAppear {
            generateQRCode()
        }
    }
    
    private func generateDeepLinkURL() -> String {
        let path = Array(deepLinks.values)[selectedDeepLink]
        
        if path == "/payslip" {
            return "payslipmax://\(path)?id=\(payslipId)"
        } else {
            return "payslipmax://\(path)"
        }
    }
    
    private func generateQRCode() {
        // In a real implementation, we would generate an actual QR code
        // For now, just use a placeholder image
        // The actual QR code generation would use CIFilter:
        /*
        let url = generateDeepLinkURL()
        guard let data = url.data(using: .utf8) else { return }
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        if let outputImage = filter.outputImage {
            // Convert to UI/NSImage and set to qrImage
            // ...
        }
        */
    }
}

#Preview {
    NavigationView {
        DeepLinkQRView()
    }
} 