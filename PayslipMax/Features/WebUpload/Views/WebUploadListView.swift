import SwiftUI
import Foundation

/// Main view for web upload functionality
struct WebUploadListView: View {
    @StateObject private var viewModel: WebUploadViewModel
    @State private var showQRCode = false
    @State private var errorAlert: WebUploadError? = nil
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
        .background(FintechColors.backgroundGray)
        .alert(item: $errorAlert) { error in
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
            await viewModel.loadAllUploads()
        }
        .refreshable {
            await viewModel.loadAllUploads()
        }
        .onAppear {
            print("WebUploadListView appeared")
            // Ensure we load all uploads, including processed ones
            Task {
                await viewModel.loadAllUploads()
            }
        }
        .onChange(of: viewModel.errorMessage) { oldValue, newError in
            if let errorMessage = newError {
                errorAlert = WebUploadError(message: errorMessage)
                // Use DispatchQueue instead of Task to avoid the warning about publishing changes within view updates
                DispatchQueue.main.async {
                    viewModel.errorMessage = nil
                }
            }
        }
    }
    
    // MARK: - Component Views
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Connect to Web")
                    .font(.headline)
                    .foregroundColor(FintechColors.textPrimary)
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
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .tint(FintechColors.primaryBlue)
            Text("Loading uploads...")
                .foregroundColor(FintechColors.textSecondary)
                .padding(.top)
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "icloud.and.arrow.down")
                .font(.system(size: 60))
                .foregroundColor(FintechColors.textSecondary)
            
            VStack(spacing: 8) {
                Text("No Web Uploads")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(FintechColors.textPrimary)
                
                Text("Upload PDFs from PayslipMax.com to see them here")
                    .font(.body)
                    .foregroundColor(FintechColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if viewModel.deviceRegistrationStatus != .registered {
                Text("Make sure your device is registered to receive uploads")
                    .font(.caption)
                    .foregroundColor(FintechColors.warningAmber)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            
            Spacer()
        }
    }
    
    private var uploadsListView: some View {
        List {
            ForEach(viewModel.uploads) { upload in
                WebUploadItemView(upload: upload, onProcess: {
                    Task {
                        await viewModel.processUpload(upload)
                    }
                })
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteUpload(upload)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .listRowBackground(upload.status == .processed ? Color(.systemGray6) : nil)
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
                    .foregroundColor(FintechColors.textPrimary)
                    .lineLimit(1)
                
                HStack {
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                    
                    Text(formattedSize)
                        .font(.caption)
                        .foregroundColor(FintechColors.textSecondary)
                }
                
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(statusColor)
            }
            
            Spacer()
            
            // Action button - different options based on status
            if upload.status == .processed {
                // For processed files, offer view option
                NavigationLink(destination: {
                    let viewModel = DIContainer.shared.makePayslipsViewModel()
                    return PayslipsView(viewModel: viewModel)
                }()) {
                    Text("View in Payslips")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            } else if upload.status != .processed {
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
        ByteCountFormatter.string(fromByteCount: Int64(upload.fileSize), countStyle: .file)
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
        case .pending, .downloading:
            return FintechColors.primaryBlue
        case .downloaded, .requiresPassword:
            return FintechColors.warningAmber
        case .processed:
            return FintechColors.successGreen
        case .failed:
            return FintechColors.dangerRed
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
                            submitAndDismiss()
                        }
                    }
                
                Button(action: submitAndDismiss) {
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
                // Small delay before focusing to prevent constraint conflicts
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isPasswordFocused = true
                }
            }
        }
        // Use intrinsicSize to avoid layout constraint warnings
        .intrinsicContentSize()
    }
    
    // Helper function to dismiss the sheet after submitting
    private func submitAndDismiss() {
        if !password.isEmpty {
            dismiss()
            // Small delay to ensure dismiss completes before processing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onSubmit()
            }
        }
    }
}

// Extension to help with intrinsic content size
extension View {
    func intrinsicContentSize() -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .ignoresSafeArea(.keyboard)
    }
}

// Helper struct for displaying errors
struct WebUploadError: Identifiable {
    let id = UUID()
    let message: String
} 