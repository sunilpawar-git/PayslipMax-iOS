import SwiftUI

/// Main view for web upload functionality
struct WebUploadListView: View {
    @StateObject private var viewModel: WebUploadViewModel
    @State private var showQRCode = false
    @Environment(\.colorScheme) private var colorScheme
    
    init(viewModel: WebUploadViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack {
            headerView
            
            if viewModel.isLoading && viewModel.uploads.isEmpty {
                loadingView
            } else if viewModel.uploads.isEmpty {
                emptyStateView
            } else {
                uploadsListView
            }
        }
        .navigationTitle("Web Uploads")
        .background(Color(.systemGroupedBackground))
        .alert(item: Binding<WebUploadError?>(
            get: {
                viewModel.errorMessage.map { WebUploadError(message: $0) }
            },
            set: { _ in
                viewModel.errorMessage = nil
            }
        )) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showQRCode) {
            if let url = viewModel.registrationURL {
                QRCodeView(url: url, deviceToken: viewModel.deviceToken ?? "")
            }
        }
        .sheet(isPresented: $viewModel.showPasswordPrompt) {
            if let upload = viewModel.currentUploadRequiringPassword {
                PasswordPromptView(
                    fileName: upload.filename,
                    password: $viewModel.password,
                    onSubmit: {
                        Task {
                            await viewModel.submitPassword()
                        }
                    },
                    onCancel: {
                        viewModel.cancelPasswordPrompt()
                    }
                )
            }
        }
        .task {
            await viewModel.loadPendingUploads()
        }
        .refreshable {
            await viewModel.loadPendingUploads()
        }
    }
    
    // MARK: - Component Views
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Connect to Web")
                    .font(.headline)
                Spacer()
                Button(action: {
                    Task {
                        await viewModel.registerDevice()
                    }
                }) {
                    Text(registerButtonText)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.deviceRegistrationStatus == .registering)
                
                if viewModel.deviceRegistrationStatus == .registered {
                    Button(action: {
                        showQRCode = true
                    }) {
                        Image(systemName: "qrcode")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal)
            
            if viewModel.deviceRegistrationStatus == .registered {
                Text("Device connected to PayslipMax.com")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading uploads...")
                .foregroundColor(.secondary)
                .padding(.top)
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Web Uploads")
                .font(.title2)
            
            Text("Register your device and upload files from PayslipMax.com to see them here.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
            
            if viewModel.deviceRegistrationStatus != .registered {
                Button(action: {
                    Task {
                        await viewModel.registerDevice()
                    }
                }) {
                    Text("Register Device")
                        .frame(minWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var uploadsListView: some View {
        List {
            ForEach(viewModel.uploads) { upload in
                WebUploadItemView(upload: upload, onProcess: {
                    Task {
                        await viewModel.processUpload(upload)
                    }
                })
            }
        }
        .listStyle(.insetGrouped)
        .overlay(
            viewModel.isLoading ?
            ProgressView()
                .scaleEffect(1.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.1))
            : nil
        )
    }
    
    private var registerButtonText: String {
        switch viewModel.deviceRegistrationStatus {
        case .notRegistered, .failed:
            return "Register"
        case .registering:
            return "Registering..."
        case .registered:
            return "Reconnect"
        }
    }
}

/// Individual upload item view
struct WebUploadItemView: View {
    let upload: WebUploadInfo
    let onProcess: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(upload.filename)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack {
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formattedSize)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(statusColor)
            }
            
            Spacer()
            
            // Action button
            if upload.status != .processed {
                Button(action: onProcess) {
                    Text(actionText)
                }
                .disabled(upload.status == .downloading)
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Computed Properties
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: upload.uploadedAt)
    }
    
    private var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: upload.fileSize, countStyle: .file)
    }
    
    private var statusText: String {
        switch upload.status {
        case .pending:
            return "Pending Download"
        case .downloading:
            return "Downloading..."
        case .downloaded:
            return upload.isPasswordProtected ? "Password Required" : "Ready to Process"
        case .processed:
            return "Processed"
        case .failed:
            return "Processing Failed"
        case .requiresPassword:
            return "Password Required"
        }
    }
    
    private var statusColor: Color {
        switch upload.status {
        case .pending, .downloading, .downloaded:
            return .blue
        case .processed:
            return .green
        case .failed:
            return .red
        case .requiresPassword:
            return .orange
        }
    }
    
    private var statusIcon: String {
        switch upload.status {
        case .pending:
            return "arrow.down.circle"
        case .downloading:
            return "arrow.down.circle.fill"
        case .downloaded:
            return "doc.circle"
        case .processed:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.circle.fill"
        case .requiresPassword:
            return "lock.circle.fill"
        }
    }
    
    private var actionText: String {
        switch upload.status {
        case .pending:
            return "Download"
        case .downloading:
            return "Downloading"
        case .downloaded:
            return "Process"
        case .requiresPassword:
            return "Enter Password"
        case .failed:
            return "Retry"
        case .processed:
            return "" // No action for processed files
        }
    }
}

/// QR Code view for device registration
struct QRCodeView: View {
    let url: URL
    let deviceToken: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Scan this QR code on the PayslipMax website to link your device")
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
                    
                    Text(deviceToken)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .contextMenu {
                            Button(action: {
                                UIPasteboard.general.string = deviceToken
                            }) {
                                Label("Copy Code", systemImage: "doc.on.doc")
                            }
                        }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 30)
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

/// Password prompt view
struct PasswordPromptView: View {
    let fileName: String
    @Binding var password: String
    let onSubmit: () -> Void
    let onCancel: () -> Void
    
    @FocusState private var isPasswordFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("This PDF is password protected")
                    .font(.headline)
                
                Text("Enter the password for \(fileName)")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                    .focused($isPasswordFocused)
                    .onSubmit {
                        if !password.isEmpty {
                            onSubmit()
                        }
                    }
                
                Button(action: onSubmit) {
                    Text("Submit")
                        .frame(minWidth: 200)
                }
                .buttonStyle(.borderedProminent)
                .disabled(password.isEmpty)
                
                Spacer()
            }
            .padding(.top, 30)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
            }
            .onAppear {
                isPasswordFocused = true
            }
        }
    }
}

// Helper struct for displaying errors
struct WebUploadError: Identifiable {
    let id = UUID()
    let message: String
} 