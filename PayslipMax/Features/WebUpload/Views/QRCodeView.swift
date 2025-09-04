import SwiftUI
import CoreImage.CIFilterBuiltins

/// QR Code view for device registration
struct QRCodeView: View {
    let url: URL
    let deviceToken: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Connect Your Device")
                        .font(.title2)
                        .bold()
                        .padding(.top)
                    
                    VStack(spacing: 16) {
                        Text("How to use this feature:")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(alignment: .top, spacing: 12) {
                            Text("1")
                                .font(.headline)
                                .padding(8)
                                .background(Circle().fill(Color.blue))
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Visit PayslipMax Website")
                                    .font(.subheadline)
                                    .bold()
                                Text("Go to payslipmax.com on your computer")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        HStack(alignment: .top, spacing: 12) {
                            Text("2")
                                .font(.headline)
                                .padding(8)
                                .background(Circle().fill(Color.blue))
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Scan or Enter Code")
                                    .font(.subheadline)
                                    .bold()
                                Text("Use the QR code or enter the device code on the website")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        
                        HStack(alignment: .top, spacing: 12) {
                            Text("3")
                                .font(.headline)
                                .padding(8)
                                .background(Circle().fill(Color.blue))
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Upload PDFs")
                                    .font(.subheadline)
                                    .bold()
                                Text("Any PDFs uploaded on the website will appear in this app")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    Text("Scan this QR code on the PayslipMax website")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if let qrImage = generateQRCode(from: url) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .cornerRadius(8)
                            .shadow(radius: 2)
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 200, height: 200)
                        .overlay(
                            Text("QR Code unavailable")
                                .foregroundColor(.secondary)
                        )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Or enter this code on the website:")
                        .font(.headline)
                    
                        HStack {
                    Text(deviceToken)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                            
                            Button(action: {
                                UIPasteboard.general.string = deviceToken
                            }) {
                                Image(systemName: "doc.on.clipboard")
                                    .padding(8)
                            }
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                        }
                }
                .padding(.horizontal)
                }
                .padding(.bottom, 30)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func generateQRCode(from url: URL) -> UIImage? {
        let data = url.absoluteString.data(using: .utf8)
        
        guard let qrFilter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        
        qrFilter.setValue(data, forKey: "inputMessage")
        qrFilter.setValue("H", forKey: "inputCorrectionLevel")
        
        guard let qrImage = qrFilter.outputImage else {
            return nil
        }
        
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledQrImage = qrImage.transformed(by: transform)
        
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledQrImage, from: scaledQrImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Preview
#if DEBUG
struct QRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeView(
            url: URL(string: "https://payslipmax.com/device/123456")!,
            deviceToken: "ABC123"
        )
    }
}
#endif
