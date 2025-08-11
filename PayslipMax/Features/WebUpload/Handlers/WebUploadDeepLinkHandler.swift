import Foundation

/// Protocol for handling deep links
protocol DeepLinkHandlerProtocol {
    /// Process a URL received from a deep link
    func processURL(_ url: URL) -> Bool
    
    /// Process Universal Link from the website
    func processUniversalLink(_ url: URL) -> Bool
}

/// Implementation of the deep link handler
class WebUploadDeepLinkHandler: DeepLinkHandlerProtocol {
    private let webUploadService: WebUploadServiceProtocol
    private let securityService: DeepLinkSecurityServiceProtocol
    
    init(webUploadService: WebUploadServiceProtocol, securityService: DeepLinkSecurityServiceProtocol) {
        self.webUploadService = webUploadService
        self.securityService = securityService
    }
    
    func processURL(_ url: URL) -> Bool {
        print("WebUploadDeepLinkHandler.processURL called with: \(url.absoluteString)")
        
        // Check if the URL is a payslipmax custom scheme URL
        guard url.scheme == "payslipmax" else {
            print("WebUploadDeepLinkHandler: Not a payslipmax:// URL")
            return false
        }
        
        // Extract components
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            print("WebUploadDeepLinkHandler: Failed to create URLComponents")
            return false
        }
        
        // Get host - for payslipmax://upload URLs, host should be "upload"
        let host = components.host
        print("WebUploadDeepLinkHandler: URL host is: \(host ?? "nil")")
        
        // Try to handle as an upload URL first
        if host == "upload" {
            return handleUploadURL(components)
        }
        
        // If we got here, try other paths
        switch host {
        case "process":
            return handleProcessURL(components)
        default:
            print("WebUploadDeepLinkHandler: Unrecognized host: \(host ?? "nil")")
            return false
        }
    }
    
    func processUniversalLink(_ url: URL) -> Bool {
        // Check if the URL is from our domain
        guard url.host == "payslipmax.com" || url.host == "www.payslipmax.com" else {
            return false
        }
        
        // Parse path components
        let pathComponents = url.pathComponents
        
        // Check for upload paths
        if pathComponents.count >= 2 && pathComponents[1] == "upload" {
            // Extract upload information from URL
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                return false
            }
            
            return handleUploadURL(components)
        }
        
        return false
    }
    
    // MARK: - Private Methods
    
    private func handleUploadURL(_ components: URLComponents) -> Bool {
        // Kick off async validation and processing; return true if we recognized the URL
        Task {
            do {
                let validated = try await securityService.validate(components: components)
                let uploadInfo = WebUploadInfo(
                    stringID: validated.idString,
                    filename: validated.filename,
                    uploadedAt: Date(),
                    fileSize: validated.size,
                    isPasswordProtected: validated.isProtected,
                    source: "web",
                    status: .pending,
                    secureToken: validated.token
                )
                
                print("WebUploadDeepLinkHandler: Starting download for ID: \(validated.idString)")
                let downloadedURL = try await webUploadService.downloadFile(from: uploadInfo)
                
                guard FileManager.default.fileExists(atPath: downloadedURL.path) else {
                    print("WebUploadDeepLinkHandler: File doesn't exist after download at \(downloadedURL.path)")
                    throw NSError(domain: "WebUploadErrorDomain", code: 3, userInfo: [NSLocalizedDescriptionKey: "File not found after download"])
                }
                
                let pendingUploads = await webUploadService.getPendingUploads()
                if let updatedUploadInfo = pendingUploads.first(where: { $0.id == uploadInfo.id || ($0.stringID != nil && $0.stringID == validated.idString) }) {
                    if let localURL = updatedUploadInfo.localURL, FileManager.default.fileExists(atPath: localURL.path) {
                        print("WebUploadDeepLinkHandler: File downloaded to \(localURL.path)")
                        if !validated.isProtected {
                            try await Task.sleep(nanoseconds: 1_000_000_000)
                            try await webUploadService.processDownloadedFile(uploadInfo: updatedUploadInfo, password: nil)
                        }
                    } else {
                        print("WebUploadDeepLinkHandler: Local URL is missing or file doesn't exist")
                        throw NSError(domain: "WebUploadErrorDomain", code: 4, userInfo: [NSLocalizedDescriptionKey: "Local file doesn't exist"])
                    }
                } else {
                    print("WebUploadDeepLinkHandler: Could not find updated upload info after download")
                    throw NSError(domain: "WebUploadErrorDomain", code: 5, userInfo: [NSLocalizedDescriptionKey: "File not found in uploads list"])
                }
            } catch {
                print("WebUploadDeepLinkHandler: Deep link processing failed: \(error.localizedDescription)")
            }
        }
        return true
    }
    
    private func handleProcessURL(_ components: URLComponents) -> Bool {
        // Get query parameters
        guard let queryItems = components.queryItems else {
            return false
        }
        
        // Extract required parameters
        guard let idString = queryItems.first(where: { $0.name == "id" })?.value,
              let id = UUID(uuidString: idString) else {
            return false
        }
        
        // Get optional parameters
        let password = queryItems.first(where: { $0.name == "password" })?.value
        
        if let password = password {
            do {
                try webUploadService.savePassword(for: id, password: password)
            } catch {
                print("Failed to save password: \(error)")
                return false
            }
        }
        
        // Process the upload (in background)
        Task {
            do {
                // Get pending uploads
                let pendingUploads = await webUploadService.getPendingUploads()
                
                // Find the upload with matching ID
                guard let upload = pendingUploads.first(where: { $0.id == id }) else {
                    return
                }
                
                // Get password from storage if not provided
                let storedPassword = password ?? webUploadService.getPassword(for: id)
                
                // Process the file
                try await webUploadService.processDownloadedFile(uploadInfo: upload, password: storedPassword)
            } catch {
                print("Failed to process upload: \(error)")
            }
        }
        
        return true
    }
} 