import SwiftUI
import AVFoundation

// MARK: - QR Scanner View

struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var scanner = QRCodeScanner()

    let onScan: (BackupQRInfo) -> Void

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                if let previewLayer = scanner.getPreviewLayer() {
                    QRCameraPreview(previewLayer: previewLayer)
                        .ignoresSafeArea()
                }

                // Scanning overlay
                VStack {
                    Spacer()

                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 250, height: 250)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(FintechColors.primaryBlue, lineWidth: 2)
                                .animation(.easeInOut(duration: 1.5).repeatForever(), value: true)
                        )

                    Text("Position QR code within the frame")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.top, 20)

                    Spacer()
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.white)
            )
            .onAppear {
                do {
                    try scanner.startScanning()
                } catch {
                    print("Failed to start QR scanning: \(error)")
                    dismiss()
                }
            }
            .onDisappear {
                scanner.stopScanning()
            }
        }
    }
}

// MARK: - QR Camera Preview

struct QRCameraPreview: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        previewLayer.frame = uiView.bounds
    }
}
