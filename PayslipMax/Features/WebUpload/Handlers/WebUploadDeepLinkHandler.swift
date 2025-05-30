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
        // Get query parameters
        guard let queryItems = components.queryItems else {
            print("WebUploadDeepLinkHandler: Missing query items")
            return false
        }
        
        // Log all parameters for debugging
        print("WebUploadDeepLinkHandler: Received query items: \(queryItems)")
        
        // Extract required parameters that are common to both formats
        guard let idString = queryItems.first(where: { $0.name == "id" })?.value,
              let filename = queryItems.first(where: { $0.name == "filename" })?.value,
              let sizeString = queryItems.first(where: { $0.name == "size" })?.value,
              let size = Int(sizeString) else {
            print("WebUploadDeepLinkHandler: Missing required parameters (id, filename, size)")
            return false
        }
        
        // Check which format we're dealing with
        let hasToken = queryItems.first(where: { $0.name == "token" })?.value != nil
        let hasHash = queryItems.first(where: { $0.name == "hash" })?.value != nil
        
        var token: String
        var isProtected: Bool = false
        
        if hasToken {
            // New format: has token and protected parameters
            guard let tokenValue = queryItems.first(where: { $0.name == "token" })?.value else {
                print("WebUploadDeepLinkHandler: Missing token parameter in new format")
                return false
            }
            token = tokenValue
            
            if let protectedString = queryItems.first(where: { $0.name == "protected" })?.value {
                isProtected = Bool(protectedString) ?? false
            }
            
            print("WebUploadDeepLinkHandler: Using new format with token")
        } else if hasHash {
            // Old format: has hash and timestamp parameters
            guard let hashValue = queryItems.first(where: { $0.name == "hash" })?.value else {
                print("WebUploadDeepLinkHandler: Missing hash parameter in old format")
                return false
            }
            
            // Use hash as token for backward compatibility
            token = hashValue
            
            // Check if filename suggests password protection
            let lowercaseFilename = filename.lowercased()
            isProtected = lowercaseFilename.contains("password") || lowercaseFilename.contains("protected")
            
            print("WebUploadDeepLinkHandler: Using old format with hash as token")
        } else {
            print("WebUploadDeepLinkHandler: No token or hash found - cannot proceed")
            return false
        }
        
        // Use the original string ID directly
        print("WebUploadDeepLinkHandler: Processing upload - ID: \(idString), Filename: \(filename), Protected: \(isProtected)")
        
        // Create the upload info with the string ID
        let uploadInfo = WebUploadInfo(
            stringID: idString,
            filename: filename,
            uploadedAt: Date(),
            fileSize: size,
            isPasswordProtected: isProtected,
            source: "web",
            status: .pending,
            secureToken: token
        )
        
        // Start the download process
        print("WebUploadDeepLinkHandler: Starting download for ID: \(idString)")
        Task {
            do {
                // Tell service to download the file and get the updated WebUploadInfo with localURL set
                let downloadedURL = try await webUploadService.downloadFile(from: uploadInfo)
                
                // Verify file was downloaded successfully and exists
                guard FileManager.default.fileExists(atPath: downloadedURL.path) else {
                    print("WebUploadDeepLinkHandler: File doesn't exist after download at \(downloadedURL.path)")
                    throw NSError(domain: "WebUploadErrorDomain", code: 3, 
                                 userInfo: [NSLocalizedDescriptionKey: "File not found after download"])
                }
                
                // Get the latest state of the upload from the service (which will have localURL)
                let pendingUploads = await webUploadService.getPendingUploads()
                
                if let updatedUploadInfo = pendingUploads.first(where: { 
                    // Match by UUID
                    $0.id == uploadInfo.id || 
                    // Match by string ID
                    ($0.stringID != nil && $0.stringID == idString) }) {
                    
                    print("WebUploadDeepLinkHandler: Found uploaded file in pending uploads")
                    
                    // Double check the local URL exists
                    if let localURL = updatedUploadInfo.localURL,
                       FileManager.default.fileExists(atPath: localURL.path) {
                        
                        print("WebUploadDeepLinkHandler: File downloaded to \(localURL.path)")
                        
                        // Proceed with processing if not password protected
                        if !isProtected {
                            // Add a small delay to ensure file operations have completed
                            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                            try await webUploadService.processDownloadedFile(uploadInfo: updatedUploadInfo, password: nil)
                        }
                    } else {
                        print("WebUploadDeepLinkHandler: Local URL is missing or file doesn't exist")
                        throw NSError(domain: "WebUploadErrorDomain", code: 4, 
                                     userInfo: [NSLocalizedDescriptionKey: "Local file doesn't exist"])
                    }
                } else {
                    print("WebUploadDeepLinkHandler: Could not find updated upload info after download")
                    throw NSError(domain: "WebUploadErrorDomain", code: 5, userInfo: [NSLocalizedDescriptionKey: "File not found in uploads list"])
                }
            } catch {
                print("WebUploadDeepLinkHandler: Failed to process upload: \(error)")
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