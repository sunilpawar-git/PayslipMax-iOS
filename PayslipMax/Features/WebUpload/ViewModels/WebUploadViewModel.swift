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
        
        uploads = await webUploadService.getPendingUploads()
        
        isLoading = false
    }
    
    /// Load all uploads including processed ones
    func loadAllUploads() async {
        isLoading = true
        errorMessage = nil
        
        uploads = await webUploadService.getAllUploads()
        
        isLoading = false
    }
    
    /// Delete a specific upload
    func deleteUpload(_ upload: WebUploadInfo) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await webUploadService.deleteUpload(upload)
            // The uploads array will be updated automatically through the publisher
        } catch {
            errorMessage = "Failed to delete upload: \(error.localizedDescription)"
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
        
        // Store current password value and close the prompt first
        let enteredPassword = password
        let uploadToProcess = upload
        
        // Reset UI state immediately to avoid conflicts with other alert dialogs
        showPasswordPrompt = false
        currentUploadRequiringPassword = nil
        password = ""
        
        // Introduce a small delay before processing to prevent UI state conflicts
        try? await Task.sleep(nanoseconds: 500_000_000) // 500ms delay
        
        do {
            // Save the password
            try webUploadService.savePassword(for: uploadToProcess.id, password: enteredPassword)
            
            // Get an updated copy of the upload if needed
            var updatedUpload = uploadToProcess
            if let freshUpload = uploads.first(where: { $0.id == uploadToProcess.id }) {
                updatedUpload = freshUpload
            }
            
            // Process the file with the password
            try await webUploadService.processDownloadedFile(uploadInfo: updatedUpload, password: enteredPassword)
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
                // Check if the file actually exists at the expected location
                if let localURL = upload.localURL, 
                   FileManager.default.fileExists(atPath: localURL.path) {
                    // Try to process with password if we have one
                    let password = webUploadService.getPassword(for: upload.id)
                    try await webUploadService.processDownloadedFile(uploadInfo: upload, password: password)
                } else {
                    // File doesn't exist, try downloading again
                    let _ = try await webUploadService.downloadFile(from: upload)
                    
                    // Re-fetch the updated upload with the new local URL
                    let updatedUploads = await webUploadService.getPendingUploads()
                    if let updatedUpload = updatedUploads.first(where: { $0.id == upload.id || $0.stringID == upload.stringID }) {
                        // If not password protected, try to process
                        if !updatedUpload.isPasswordProtected {
                            try await webUploadService.processDownloadedFile(uploadInfo: updatedUpload, password: nil as String?)
                        }
                    }
                }
            } else {
                // Download the file first
                let _ = try await webUploadService.downloadFile(from: upload)
                
                // Re-fetch the updated upload with the new local URL
                let updatedUploads = await webUploadService.getPendingUploads()
                if let updatedUpload = updatedUploads.first(where: { $0.id == upload.id || $0.stringID == upload.stringID }) {
                    // If not password protected, try to process
                    if !updatedUpload.isPasswordProtected {
                        try await webUploadService.processDownloadedFile(uploadInfo: updatedUpload, password: nil as String?)
                    }
                }
            }
        } catch let error as PDFProcessingError where error == .passwordProtected {
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