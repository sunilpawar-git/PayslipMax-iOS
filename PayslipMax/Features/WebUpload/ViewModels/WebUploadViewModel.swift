import Foundation
import Combine
import SwiftUI

/// View model for managing web uploads
@MainActor
class WebUploadViewModel: ObservableObject {
    // Published properties for UI
    @Published var uploads: [WebUploadInfo] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var showPasswordPrompt: Bool = false
    @Published var currentUploadRequiringPassword: WebUploadInfo? = nil
    @Published var password: String = ""
    @Published var deviceRegistrationStatus: RegistrationStatus = .notRegistered
    @Published var deviceToken: String? = nil
    
    // URL for QR code generation
    var registrationURL: URL? {
        guard let token = deviceToken else { return nil }
        return URL(string: "https://payslipmax.com/link-device?token=\(token)")
    }
    
    // Dependencies
    private let webUploadService: WebUploadServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(webUploadService: WebUploadServiceProtocol) {
        self.webUploadService = webUploadService
        
        // Subscribe to uploads publisher
        webUploadService.uploadsPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] uploads in
                self?.uploads = uploads
                self?.checkForPasswordRequiredUploads()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Load pending uploads
    func loadPendingUploads() async {
        isLoading = true
        errorMessage = nil
        
        do {
            uploads = await webUploadService.getPendingUploads()
            checkForPasswordRequiredUploads()
        } catch {
            errorMessage = "Failed to load uploads: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Register device for web uploads
    func registerDevice() async {
        isLoading = true
        errorMessage = nil
        deviceRegistrationStatus = .registering
        
        do {
            let token = try await webUploadService.registerDevice()
            deviceToken = token
            deviceRegistrationStatus = .registered
        } catch {
            errorMessage = "Failed to register device: \(error.localizedDescription)"
            deviceRegistrationStatus = .failed
        }
        
        isLoading = false
    }
    
    /// Submit password for a protected PDF
    func submitPassword() async {
        guard let upload = currentUploadRequiringPassword, !password.isEmpty else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Save the password
            try webUploadService.savePassword(for: upload.id, password: password)
            
            // Process the file
            try await webUploadService.processDownloadedFile(uploadInfo: upload, password: password)
            
            // Reset UI state
            showPasswordPrompt = false
            currentUploadRequiringPassword = nil
            password = ""
        } catch {
            errorMessage = "Failed to process file: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Reset password prompt
    func cancelPasswordPrompt() {
        showPasswordPrompt = false
        currentUploadRequiringPassword = nil
        password = ""
    }
    
    /// Process a specific upload
    func processUpload(_ upload: WebUploadInfo) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Check if we have the file downloaded
            if upload.status == .downloaded || upload.localURL != nil {
                // Try to process with password if we have one
                let password = webUploadService.getPassword(for: upload.id)
                try await webUploadService.processDownloadedFile(uploadInfo: upload, password: password)
            } else {
                // Download the file first
                let _ = try await webUploadService.downloadFile(from: upload)
                
                // If not password protected, try to process
                if !upload.isPasswordProtected {
                    try await webUploadService.processDownloadedFile(uploadInfo: upload)
                }
            }
        } catch let error as PDFProcessingError where error == .passwordRequired {
            // Show password prompt
            currentUploadRequiringPassword = upload
            showPasswordPrompt = true
        } catch {
            errorMessage = "Failed to process upload: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Private Methods
    
    private func checkForPasswordRequiredUploads() {
        // Check if any uploads require a password
        if let upload = uploads.first(where: { $0.status == .requiresPassword }),
           currentUploadRequiringPassword == nil && !showPasswordPrompt {
            currentUploadRequiringPassword = upload
            showPasswordPrompt = true
        }
    }
}

// Registration status
enum RegistrationStatus {
    case notRegistered
    case registering
    case registered
    case failed
} 