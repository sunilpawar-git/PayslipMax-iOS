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
    
    init(webUploadService: WebUploadServiceProtocol) {
        self.webUploadService = webUploadService
    }
    
    func processURL(_ url: URL) -> Bool {
        // Check if the URL is a payslipmax custom scheme URL
        guard url.scheme == "payslipmax" else {
            return false
        }
        
        // Extract components
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host else {
            return false
        }
        
        switch host {
        case "upload":
            return handleUploadURL(components)
        case "process":
            return handleProcessURL(components)
        default:
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
        // Get query parameters
        guard let queryItems = components.queryItems else {
            return false
        }
        
        // Extract required parameters
        guard let idString = queryItems.first(where: { $0.name == "id" })?.value,
              let id = UUID(uuidString: idString),
              let filename = queryItems.first(where: { $0.name == "filename" })?.value,
              let fileSizeString = queryItems.first(where: { $0.name == "size" })?.value,
              let fileSize = Int64(fileSizeString),
              let source = queryItems.first(where: { $0.name == "source" })?.value else {
            return false
        }
        
        // Get optional parameters
        let token = queryItems.first(where: { $0.name == "token" })?.value
        let isPasswordProtected = queryItems.first(where: { $0.name == "protected" })?.value == "true"
        
        // Create upload info
        let uploadInfo = WebUploadInfo(
            id: id,
            filename: filename,
            fileSize: fileSize,
            isPasswordProtected: isPasswordProtected,
            source: source,
            secureToken: token
        )
        
        // Process the upload (in background)
        Task {
            do {
                // Download the file
                let fileURL = try await webUploadService.downloadFile(from: uploadInfo)
                
                // Try to process it (if it's not password protected)
                if !isPasswordProtected {
                    try await webUploadService.processDownloadedFile(uploadInfo: uploadInfo)
                }
            } catch {
                print("Failed to process upload: \(error)")
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