import Foundation

/// Protocol for file download functionality
protocol FileDownloadServiceProtocol {
    func downloadFile(from uploadInfo: WebUploadInfo, to directory: URL) async throws -> URL
}

/// Service responsible for downloading files from the web upload API
class FileDownloadService: FileDownloadServiceProtocol {
    private let urlSession: URLSession
    private let fileManager: FileManager
    private let baseURL: URL
    
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
        var downloadURLComponents = URLComponents(url: baseURL.appendingPathComponent("download"), resolvingAgainstBaseURL: true)!
        
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
            throw NSError(domain: "WebUploadErrorDomain", 
                          code: 1001, 
                          userInfo: [NSLocalizedDescriptionKey: "Invalid download URL"])
        }
        
        print("FileDownloadService: Downloading from URL: \(downloadEndpoint.absoluteString)")
        
        var request = URLRequest(url: downloadEndpoint)
        request.timeoutInterval = 60 // Increase timeout for large files
        
        // Create a destination for the file
        let destinationURL = directory.appendingPathComponent(uploadInfo.filename)
        
        // If the file already exists, remove it
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        // Download the file with proper error handling and retry
        print("FileDownloadService: Starting download task")
        
        // Maximum number of retries
        let maxRetries = 3
        var retryCount = 0
        var lastError: Error? = nil
        
        // Retry loop
        while retryCount < maxRetries {
            do {
                let (downloadURL, response) = try await urlSession.download(for: request)
                
                // Log response
                if let httpResponse = response as? HTTPURLResponse {
                    print("FileDownloadService: Received HTTP response code: \(httpResponse.statusCode)")
                    
                    // Handle different status codes
                    switch httpResponse.statusCode {
                    case 200:
                        // Success - continue with download handling
                        break
                        
                    case 401, 403:
                        // Authentication error
                        throw NSError(domain: "WebUploadErrorDomain", 
                                     code: httpResponse.statusCode, 
                                     userInfo: [NSLocalizedDescriptionKey: "Authentication error: Not authorized to download this file"])
                        
                    case 404:
                        // File not found
                        throw NSError(domain: "WebUploadErrorDomain", 
                                     code: httpResponse.statusCode, 
                                     userInfo: [NSLocalizedDescriptionKey: "File not found on server"])
                        
                    case 400...499:
                        // Other client errors
                        throw NSError(domain: "WebUploadErrorDomain", 
                                     code: httpResponse.statusCode, 
                                     userInfo: [NSLocalizedDescriptionKey: "Download failed - client error: \(httpResponse.statusCode)"])
                        
                    case 500...599:
                        // Server errors - these might be temporary, so we'll retry
                        print("FileDownloadService: Server error \(httpResponse.statusCode) - will retry")
                        throw NSError(domain: "WebUploadErrorDomain", 
                                     code: httpResponse.statusCode, 
                                     userInfo: [NSLocalizedDescriptionKey: "Server error \(httpResponse.statusCode)"])
                        
                    default:
                        // Unexpected status codes
                        print("FileDownloadService: Unexpected status code \(httpResponse.statusCode)")
                        throw NSError(domain: "WebUploadErrorDomain", 
                                     code: httpResponse.statusCode, 
                                     userInfo: [NSLocalizedDescriptionKey: "Unexpected response: \(httpResponse.statusCode)"])
                    }
                }
                
                // Move the file to our destination
                try fileManager.moveItem(at: downloadURL, to: destinationURL)
                print("FileDownloadService: File downloaded successfully to: \(destinationURL.path)")
                
                // Verify the file exists and has content
                guard fileManager.fileExists(atPath: destinationURL.path),
                      let attributes = try? fileManager.attributesOfItem(atPath: destinationURL.path),
                      let fileSize = attributes[.size] as? Int,
                      fileSize > 0 else {
                    
                    print("FileDownloadService: Downloaded file is invalid or empty")
                    throw NSError(domain: "WebUploadErrorDomain", 
                                 code: 1006, 
                                 userInfo: [NSLocalizedDescriptionKey: "Downloaded file is invalid or empty"])
                }
                
                // Return the URL where the file was saved
                return destinationURL
                
            } catch let urlError as URLError {
                // Network-related errors that might be worth retrying
                lastError = urlError
                retryCount += 1
                
                print("FileDownloadService: Download attempt \(retryCount) failed with URLError: \(urlError.localizedDescription)")
                
                // Check if we should retry based on the error
                let shouldRetry: Bool
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost:
                    // These are network issues worth retrying
                    shouldRetry = true
                default:
                    // Other URL errors might not be worth retrying
                    shouldRetry = false
                }
                
                if retryCount >= maxRetries || !shouldRetry {
                    print("FileDownloadService: Giving up after \(retryCount) attempts")
                    
                    // Create a more helpful error message
                    let errorMessage: String
                    switch urlError.code {
                    case .notConnectedToInternet:
                        errorMessage = "No internet connection. Please check your network and try again."
                    case .timedOut:
                        errorMessage = "Download timed out. The file may be too large or the server is busy."
                    case .cannotFindHost, .cannotConnectToHost:
                        errorMessage = "Cannot connect to server. Please verify the API is available."
                    case .networkConnectionLost:
                        errorMessage = "Network connection was lost during download."
                    default:
                        errorMessage = "Download failed: \(urlError.localizedDescription)"
                    }
                    
                    throw NSError(domain: "WebUploadErrorDomain", 
                                 code: urlError.code.rawValue, 
                                 userInfo: [NSLocalizedDescriptionKey: errorMessage])
                } else {
                    // Wait before retrying (exponential backoff)
                    let waitTime = TimeInterval(pow(2.0, Double(retryCount - 1)))
                    print("FileDownloadService: Waiting \(waitTime) seconds before retry...")
                    try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                }
                
            } catch {
                // Other errors are generally not worth retrying
                print("FileDownloadService: Download failed with non-network error: \(error)")
                throw error
            }
        }
        
        // If we get here, we've exhausted retries with a URLError
        if let lastError = lastError {
            throw lastError
        } else {
            throw NSError(domain: "WebUploadErrorDomain", 
                         code: 1007, 
                         userInfo: [NSLocalizedDescriptionKey: "Download failed after \(maxRetries) attempts"])
        }
    }
} 