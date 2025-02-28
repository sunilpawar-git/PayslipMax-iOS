import SwiftUI

/// View for changing the PIN
struct ChangePinView: View {
    /// View model for security
    @ObservedObject var viewModel: SecurityViewModel
    
    /// Navigation router
    @EnvironmentObject private var router: NavRouter
    
    var body: some View {
        Form {
            Section(header: Text("Current PIN")) {
                SecureField("Enter current PIN", text: $viewModel.currentPin)
                    .keyboardType(.numberPad)
                    .textContentType(.password)
            }
            
            Section(header: Text("New PIN")) {
                SecureField("Enter new PIN", text: $viewModel.newPin)
                    .keyboardType(.numberPad)
                    .textContentType(.newPassword)
                
                SecureField("Confirm new PIN", text: $viewModel.confirmPin)
                    .keyboardType(.numberPad)
                    .textContentType(.newPassword)
            }
            
            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
            
            if let successMessage = viewModel.successMessage {
                Section {
                    Text(successMessage)
                        .foregroundColor(.green)
                }
            }
            
            Section {
                Button {
                    Task {
                        if await viewModel.changePin() {
                            // Wait a moment to show success message
                            try? await Task.sleep(nanoseconds: 1_500_000_000)
                            await MainActor.run {
                                router.dismissSheet()
                            }
                        }
                    }
                } label: {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("Change PIN")
                    }
                }
                .disabled(viewModel.isLoading)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Change PIN")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    router.dismissSheet()
                }
            }
        }
    }
}

/// View for adding a new payslip
struct AddPayslipView: View {
    /// Navigation router
    @EnvironmentObject private var router: NavRouter
    
    /// Selected method
    @State private var selectedMethod = 0
    
    /// Available methods
    private let methods = ["Upload PDF", "Scan Document", "Manual Entry"]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Payslip")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("Choose how you want to add your payslip")
                .foregroundColor(.secondary)
            
            Picker("Method", selection: $selectedMethod) {
                ForEach(0..<methods.count, id: \.self) { index in
                    Text(methods[index])
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            // Method-specific content
            VStack(spacing: 16) {
                switch selectedMethod {
                case 0: // Upload PDF
                    uploadPDFView
                case 1: // Scan Document
                    scanDocumentView
                case 2: // Manual Entry
                    manualEntryView
                default:
                    EmptyView()
                }
            }
            .padding()
            
            Spacer()
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    router.dismissSheet()
                }
            }
        }
    }
    
    /// Upload PDF view
    private var uploadPDFView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Drag and drop your PDF file here or click to browse")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Browse Files") {
                // In a real implementation, this would open a file picker
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    /// Scan document view
    private var scanDocumentView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("Use your camera to scan your payslip")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Open Camera") {
                router.presentSheet(.scanner)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    /// Manual entry view
    private var manualEntryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "keyboard")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Manually enter your payslip details")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Start Entry") {
                // In a real implementation, this would navigate to a form
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

/// View for scanning documents
struct ScannerView: View {
    /// Navigation router
    @EnvironmentObject private var router: NavRouter
    
    var body: some View {
        VStack {
            Text("Scanner")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            Text("This is a placeholder for the document scanner")
                .foregroundColor(.secondary)
                .padding()
            
            // Placeholder for camera view
            Rectangle()
                .fill(Color.black.opacity(0.8))
                .frame(maxWidth: .infinity)
                .frame(height: 400)
                .overlay(
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                )
                .cornerRadius(12)
                .padding()
            
            HStack(spacing: 20) {
                Button {
                    router.dismissSheet()
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button {
                    // In a real implementation, this would capture the image
                    router.dismissSheet()
                } label: {
                    Text("Capture")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        ChangePinView(viewModel: SecurityViewModel())
            .environmentObject(NavRouter())
    }
} 