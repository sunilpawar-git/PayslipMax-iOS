#if DEBUG
import SwiftUI

/// Debug view for testing WebUpload functionality
struct WebUploadDebugView: View {
    @State private var useMockService: Bool = false
    @State private var baseURL: String = "https://payslipmax.com/api"
    @State private var showingMessage: Bool = false
    @State private var message: String = ""
    @State private var testResult: String = ""
    @State private var isRunningTest: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Service Configuration")) {
                    Toggle("Use Mock Service", isOn: $useMockService)
                        .onChange(of: useMockService) { oldValue, newValue in
                            DIContainer.shared.toggleWebUploadMock(newValue)
                            showMessage("Service set to: \(newValue ? "Mock" : "Real API")")
                        }
                    
                    VStack(alignment: .leading) {
                        Text("API Base URL")
                        TextField("Base URL", text: $baseURL)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .keyboardType(.URL)
                        
                        Button("Apply URL") {
                            updateBaseURL()
                        }
                        .buttonStyle(.bordered)
                        .padding(.top, 4)
                    }
                }
                
                Section(header: Text("Connection Test")) {
                    Button("Test Device Registration") {
                        runDeviceRegistrationTest()
                    }
                    .disabled(isRunningTest)
                    
                    Button("Test Pending Uploads") {
                        runPendingUploadsTest()
                    }
                    .disabled(isRunningTest)
                    
                    if !testResult.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Test Results:")
                                .font(.headline)
                            
                            Text(testResult)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(testResult.contains("Error") ? .red : .primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section(header: Text("Preset Environments")) {
                    Button("Local Development (localhost:8000)") {
                        baseURL = "http://localhost:8000/api"
                        updateBaseURL()
                    }
                    
                    Button("Production (payslipmax.com)") {
                        baseURL = "https://payslipmax.com/api"
                        updateBaseURL()
                    }
                    
                    Button("Staging") {
                        baseURL = "https://staging.payslipmax.com/api"
                        updateBaseURL()
                    }
                }
            }
            .navigationTitle("Web Upload Debug")
            .alert(message, isPresented: $showingMessage) {
                Button("OK") {}
            }
        }
    }
    
    private func showMessage(_ text: String) {
        message = text
        showingMessage = true
    }
    
    private func updateBaseURL() {
        guard let url = URL(string: baseURL) else {
            showMessage("Invalid URL format")
            return
        }
        
        DIContainer.shared.setWebAPIBaseURL(url)
        showMessage("Base URL updated to: \(url.absoluteString)")
    }
    
    private func runDeviceRegistrationTest() {
        isRunningTest = true
        testResult = "Testing device registration...\n"
        
        Task {
            do {
                let service = DIContainer.shared.makeWebUploadService()
                let token = try await service.registerDevice()
                await MainActor.run {
                    testResult += "✅ Successfully registered device\n"
                    testResult += "Token: \(token)\n"
                    isRunningTest = false
                }
            } catch {
                await MainActor.run {
                    testResult += "❌ Error: \(error.localizedDescription)\n"
                    if let nsError = error as NSError? {
                        testResult += "Domain: \(nsError.domain), Code: \(nsError.code)\n"
                    }
                    isRunningTest = false
                }
            }
        }
    }
    
    private func runPendingUploadsTest() {
        isRunningTest = true
        testResult = "Testing pending uploads...\n"
        
        Task {
            do {
                let service = DIContainer.shared.makeWebUploadService()
                
                // First register to ensure we have a token
                _ = try await service.registerDevice()
                
                // Then check for pending uploads
                let uploads = await service.getPendingUploads()
                
                await MainActor.run {
                    testResult += "✅ Successfully checked for pending uploads\n"
                    testResult += "Found \(uploads.count) pending uploads\n"
                    
                    if !uploads.isEmpty {
                        testResult += "\nUploads:\n"
                        for (index, upload) in uploads.enumerated() {
                            testResult += "[\(index + 1)] \(upload.filename) - \(upload.status)\n"
                        }
                    }
                    
                    isRunningTest = false
                }
            } catch {
                await MainActor.run {
                    testResult += "❌ Error: \(error.localizedDescription)\n"
                    if let nsError = error as NSError? {
                        testResult += "Domain: \(nsError.domain), Code: \(nsError.code)\n"
                    }
                    isRunningTest = false
                }
            }
        }
    }
}

#Preview {
    WebUploadDebugView()
}
#endif 