import Foundation

/// Service responsible for downloading files from the web upload system
protocol FileDownloadServiceProtocol {
    /// Download file from the web service
    func downloadFile(from uploadInfo: WebUploadInfo, to directory: URL) async throws -> URL
}

/// Implementation of file download service with retry logic and comprehensive error handling
class FileDownloadService: FileDownloadServiceProtocol {
    private let urlSession: URLSession
    private let fileManager: FileManager
    private let baseURL: URL
    
    private let maxRetries = 3
    
    init(
        urlSession: URLSession = .shared,
        fileManager: FileManager = .default,
        baseURL: URL
    ) {
        self.urlSession = urlSession
        self.fileManager = fileManager
        self.baseURL = baseURL
    }
    
    func downloadFile(from uploadInfo: WebUploadInfo, to directory: URL) async throws -> URL {
        print("FileDownloadService: Starting download for upload ID: \(uploadInfo.id), StringID: \(uploadInfo.stringID ?? "nil")")
        
        // Create the download URL using the website's API
        let downloadEndpoint = try createDownloadURL(for: uploadInfo)
        print("FileDownloadService: Downloading from URL: \(downloadEndpoint.absoluteString)")
        
        var request = URLRequest(url: downloadEndpoint)
        request.timeoutInterval = 60 // Increase timeout for large files
        
        // Create a destination for the file
        let destinationURL = directory.appendingPathComponent(uploadInfo.filename)
        
        // If the file already exists, remove it
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        // Download the file with retry logic
        return try await performDownloadWithRetry(request: request, destinationURL: destinationURL)
    }
    
    // MARK: - Private Methods
    
    private func createDownloadURL(for uploadInfo: WebUploadInfo) throws -> URL {
        var downloadURLComponents = URLComponents(
            url: baseURL.appendingPathComponent("download"), 
            resolvingAgainstBaseURL: true
        )!
        
        // Use the original string ID if available, otherwise use the UUID
        let idParameter = uploadInfo.stringID ?? uploadInfo.id.uuidString
        
        // Add required query parameters
        downloadURLComponents.queryItems = [
            URLQueryItem(name: "id", value: idParameter)
        ]
        
        // Add the secure token if we have one
        if let token = uploadInfo.secureToken {
            downloadURLComponents.queryItems?.append(URLQueryItem(name: "token", value: token))
        }
        
        guard let downloadEndpoint = downloadURLComponents.url else {
            print("FileDownloadService: Failed to create download URL")
            throw FileDownloadError.invalidURL
        }
        
        return downloadEndpoint
    }
    
    private func performDownloadWithRetry(request: URLRequest, destinationURL: URL) async throws -> URL {
        var retryCount = 0
        var lastError: Error? = nil
        
        // Retry loop
        while retryCount < maxRetries {
            do {
                return try await performSingleDownload(request: request, destinationURL: destinationURL)
            } catch let urlError as URLError {
                // Network-related errors that might be worth retrying
                lastError = urlError
                retryCount += 1
                
                print("FileDownloadService: Download attempt \(retryCount) failed with URLError: \(urlError.localizedDescription)")
                
                // Check if we should retry based on the error
                let shouldRetry = shouldRetryForURLError(urlError)
                
                if retryCount >= maxRetries || !shouldRetry {
                    print("FileDownloadService: Giving up after \(retryCount) attempts")
                    throw FileDownloadError.networkError(urlError)
                }
                
                // Add exponential backoff delay before retrying
                let delaySeconds = Double(1 << retryCount) // 2, 4, 8... seconds
                print("FileDownloadService: Retrying in \(delaySeconds) seconds...")
                try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
                
            } catch {
                // Other errors
                print("FileDownloadService: Download failed with error: \(error)")
                lastError = error
                retryCount += 1
                
                // For server errors, we might want to retry
                let shouldRetry = shouldRetryForGenericError(error)
                
                if retryCount >= maxRetries || !shouldRetry {
                    print("FileDownloadService: Giving up after \(retryCount) attempts")
                    throw error
                }
                
                // Add exponential backoff delay before retrying
                let delaySeconds = Double(1 << retryCount) // 2, 4, 8... seconds
                print("FileDownloadService: Retrying in \(delaySeconds) seconds...")
                try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
            }
        }
        
        // If we got here, we ran out of retries
        print("FileDownloadService: Max retries exceeded")
        if let error = lastError {
            throw error
        } else {
            throw FileDownloadError.maxRetriesExceeded
        }
    }
    
    private func performSingleDownload(request: URLRequest, destinationURL: URL) async throws -> URL {
        print("FileDownloadService: Starting download task")
        
        let (downloadURL, response) = try await urlSession.download(for: request)
        
        // Log response
        if let httpResponse = response as? HTTPURLResponse {
            print("FileDownloadService: Received HTTP response code: \(httpResponse.statusCode)")
            try validateHTTPResponse(httpResponse)
        }
        
        // Move the file to our destination
        try fileManager.moveItem(at: downloadURL, to: destinationURL)
        print("FileDownloadService: File downloaded successfully to: \(destinationURL.path)")
        
        // Verify the file exists and has content
        try validateDownloadedFile(at: destinationURL)
        
        // Return the URL where the file was saved
        return destinationURL
    }
    
    private func validateHTTPResponse(_ httpResponse: HTTPURLResponse) throws {
        switch httpResponse.statusCode {
        case 200:
            // Success - continue with download handling
            return
            
        case 401, 403:
            // Authentication error
            throw FileDownloadError.authenticationError
            
        case 404:
            // File not found
            throw FileDownloadError.fileNotFound
            
        case 400...499:
            // Other client errors
            throw FileDownloadError.clientError(httpResponse.statusCode)
            
        case 500...599:
            // Server errors - these might be temporary, so we'll retry
            print("FileDownloadService: Server error \(httpResponse.statusCode) - will retry")
            throw FileDownloadError.serverError(httpResponse.statusCode)
            
        default:
            // Unexpected status codes
            print("FileDownloadService: Unexpected status code \(httpResponse.statusCode)")
            throw FileDownloadError.unexpectedStatusCode(httpResponse.statusCode)
        }
    }
    
    private func validateDownloadedFile(at url: URL) throws {
        guard fileManager.fileExists(atPath: url.path),
              let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int,
              fileSize > 0 else {
            
            print("FileDownloadService: Downloaded file is invalid or empty")
            throw FileDownloadError.invalidDownloadedFile
        }
    }
    
    private func shouldRetryForURLError(_ urlError: URLError) -> Bool {
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost:
            // These are network issues worth retrying
            return true
        default:
            // Other URL errors might not be worth retrying
            return false
        }
    }
    
    private func shouldRetryForGenericError(_ error: Error) -> Bool {
        // For server errors, we might want to retry
        if let downloadError = error as? FileDownloadError {
            switch downloadError {
            case .serverError:
                return true
            default:
                return false
            }
        }
        return false
    }
}

// MARK: - Error Types

enum FileDownloadError: Error, LocalizedError {
    case invalidURL
    case networkError(URLError)
    case authenticationError
    case fileNotFound
    case clientError(Int)
    case serverError(Int)
    case unexpectedStatusCode(Int)
    case invalidDownloadedFile
    case maxRetriesExceeded
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid download URL"
        case .networkError(let urlError):
            return createNetworkErrorMessage(urlError)
        case .authenticationError:
            return "Authentication error: Not authorized to download this file"
        case .fileNotFound:
            return "File not found on server"
        case .clientError(let code):
            return "Download failed - client error: \(code)"
        case .serverError(let code):
            return "Server error \(code)"
        case .unexpectedStatusCode(let code):
            return "Unexpected response: \(code)"
        case .invalidDownloadedFile:
            return "Downloaded file is invalid or empty"
        case .maxRetriesExceeded:
            return "Maximum download retries exceeded"
        }
    }
    
    private func createNetworkErrorMessage(_ urlError: URLError) -> String {
        switch urlError.code {
        case .notConnectedToInternet:
            return "No internet connection. Please check your network and try again."
        case .timedOut:
            return "Download timed out. The file may be too large or server is busy."
        case .cannotFindHost, .cannotConnectToHost:
            return "Cannot connect to server. Please verify the API is available."
        default:
            return "Network error: \(urlError.localizedDescription)"
        }
    }
} 