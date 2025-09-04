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
            WebUploadHeaderView(
                deviceRegistrationStatus: viewModel.deviceRegistrationStatus,
                isRegistering: viewModel.deviceRegistrationStatus == .registering,
                onRegisterDevice: {
                    Task {
                        await viewModel.registerDevice()
                    }
                },
                onShowQRCode: {
                    showQRCode = true
                }
            )
            
            if viewModel.isLoading && viewModel.uploads.isEmpty {
                WebUploadLoadingView()
            } else if viewModel.uploads.isEmpty {
                WebUploadEmptyStateView(deviceRegistrationStatus: viewModel.deviceRegistrationStatus)
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


// Helper struct for displaying errors
struct WebUploadError: Identifiable {
    let id = UUID()
    let message: String
} 