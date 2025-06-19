import SwiftUI
import AVFoundation

// MARK: - Backup Card Component

struct BackupCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let actionTitle: String
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon and Title
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(FintechColors.textPrimary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(FintechColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }
            
            // Action Button
            Button(action: action) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(isLoading ? "Processing..." : actionTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(iconColor)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(isLoading)
        }
        .padding(16)
        .background(FintechColors.cardBackground)
        .cornerRadius(12)
        .shadow(color: FintechColors.shadow, radius: 2, x: 0, y: 1)
    }
}

// MARK: - Backup Info View

struct BackupInfoView: View {
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(FintechColors.successGreen)
                            .frame(width: 12, height: 12)
                            .padding(.top, 2)
                        
                        Text(item)
                            .font(.subheadline)
                            .foregroundColor(FintechColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(FintechColors.cardBackground.opacity(0.5))
        .cornerRadius(12)
    }
}

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

// MARK: - Success Animation View

struct BackupSuccessView: View {
    let title: String
    let subtitle: String
    @State private var showCheckmark = false
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(FintechColors.successGreen.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(FintechColors.successGreen)
                    .scaleEffect(showCheckmark ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showCheckmark)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(FintechColors.textPrimary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(FintechColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            withAnimation(.easeInOut.delay(0.2)) {
                showCheckmark = true
            }
        }
    }
}

// MARK: - Progress Indicator

struct BackupProgressView: View {
    let title: String
    let progress: Double
    let subtitle: String?
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress Circle
            ZStack {
                Circle()
                    .stroke(FintechColors.primaryBlue.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(FintechColors.primaryBlue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)
                
                Text("\(Int(progress * 100))%")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(FintechColors.textPrimary)
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(FintechColors.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(FintechColors.textSecondary)
                }
            }
        }
    }
}

// MARK: - Backup Statistics View

struct BackupStatsView: View {
    let stats: BackupStats
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Backup Statistics")
                .font(.headline)
                .foregroundColor(FintechColors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                BackupStatCard(
                    title: "Total Backups",
                    value: "\(stats.totalBackups)",
                    icon: "square.and.arrow.up",
                    color: FintechColors.primaryBlue
                )
                
                BackupStatCard(
                    title: "Last Backup",
                    value: stats.lastBackupDate?.formatted(date: .abbreviated, time: .omitted) ?? "Never",
                    icon: "clock",
                    color: FintechColors.successGreen
                )
                
                BackupStatCard(
                    title: "Data Size",
                    value: formatFileSize(stats.totalDataSize),
                    icon: "externaldrive",
                    color: FintechColors.warningAmber
                )
                
                BackupStatCard(
                    title: "Payslips",
                    value: "\(stats.totalPayslips)",
                    icon: "doc.text",
                    color: FintechColors.primaryBlue
                )
            }
        }
        .padding(16)
        .background(FintechColors.cardBackground)
        .cornerRadius(12)
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct BackupStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(FintechColors.textPrimary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(FintechColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Supporting Data Types

struct BackupStats {
    let totalBackups: Int
    let lastBackupDate: Date?
    let totalDataSize: Int
    let totalPayslips: Int
}

// MARK: - Preview Helpers

#if DEBUG
struct BackupCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            BackupCard(
                icon: "square.and.arrow.up",
                iconColor: .blue,
                title: "Create Backup",
                subtitle: "Export all your payslip data to a secure backup file",
                actionTitle: "Export Now",
                isLoading: false
            ) {
                print("Export tapped")
            }
            
            BackupCard(
                icon: "square.and.arrow.down",
                iconColor: .green,
                title: "Import Data",
                subtitle: "Restore payslips from a backup file",
                actionTitle: "Processing...",
                isLoading: true
            ) {
                print("Import tapped")
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
#endif 