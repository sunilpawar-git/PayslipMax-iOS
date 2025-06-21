import Foundation

/// Protocol defining file download functionality
protocol FileDownloadServiceProtocol {
    func downloadFile(from uploadInfo: WebUploadInfo) async throws -> URL
    func deleteUploadedFile(_ upload: WebUploadInfo) async throws
    func loadSavedUploads() async throws -> [WebUploadInfo]
    func saveUploads(_ uploads: [WebUploadInfo]) async throws
}

/// Service responsible for downloading files and managing local storage
class FileDownloadService: FileDownloadServiceProtocol {
    // MARK: - Dependencies
    private let urlSession: URLSession
    private let fileManager: FileManager
    private let baseURL: URL
    
    // MARK: - Storage
    private let uploadDirectory: URL
    
    // MARK: - Initialization
    init(
        urlSession: URLSession = .shared,
        fileManager: FileManager = .default,
        baseURL: URL = URL(string: "http://localhost:8000/api")!
    ) {
        self.urlSession = urlSession
        self.fileManager = fileManager
        self.baseURL = baseURL
        
        // Create upload directory
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.uploadDirectory = documentsDirectory.appendingPathComponent("WebUploads", isDirectory: true)
        
        try? fileManager.createDirectory(at: uploadDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Public Methods
    
    func downloadFile(from uploadInfo: WebUploadInfo) async throws -> URL {
        print("FileDownloadService: Starting download for upload ID: \(uploadInfo.id)")
        
        // Create download URL
        let downloadURL = try createDownloadURL(for: uploadInfo)
        print("FileDownloadService: Downloading from URL: \(downloadURL.absoluteString)")
        
        // Create destination URL
        let destinationURL = uploadDirectory.appendingPathComponent(uploadInfo.filename)
        
        // Remove existing file if present
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        // Download with retry logic
        return try await performDownloadWithRetry(
            from: downloadURL,
            to: destinationURL,
            filename: uploadInfo.filename
        )
    }
    
    func deleteUploadedFile(_ upload: WebUploadInfo) async throws {
        print("FileDownloadService: Deleting upload file - ID: \(upload.id)")
        
        // Delete the PDF file if it exists
        if let localURL = upload.localURL, fileManager.fileExists(atPath: localURL.path) {
            try fileManager.removeItem(at: localURL)
            print("FileDownloadService: Deleted file at \(localURL.path)")
        }
    }
    
    func loadSavedUploads() async throws -> [WebUploadInfo] {
        let uploadsFile = uploadDirectory.appendingPathComponent("uploads.json")
        
        guard fileManager.fileExists(atPath: uploadsFile.path) else {
            return []
        }
        
        let data = try Data(contentsOf: uploadsFile)
        let uploads = try JSONDecoder().decode([WebUploadInfo].self, from: data)
        
        print("FileDownloadService: Loaded \(uploads.count) saved uploads")
        return uploads
    }
    
    func saveUploads(_ uploads: [WebUploadInfo]) async throws {
        let uploadsFile = uploadDirectory.appendingPathComponent("uploads.json")
        let data = try JSONEncoder().encode(uploads)
        try data.write(to: uploadsFile)
        
        print("FileDownloadService: Saved \(uploads.count) uploads to disk")
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
        
        // Add the secure token if available
        if let token = uploadInfo.secureToken {
            downloadURLComponents.queryItems?.append(URLQueryItem(name: "token", value: token))
        }
        
        guard let downloadURL = downloadURLComponents.url else {
            throw FileDownloadError.invalidDownloadURL
        }
        
        return downloadURL
    }
    
    private func performDownloadWithRetry(
        from url: URL,
        to destinationURL: URL,
        filename: String,
        maxRetries: Int = 3
    ) async throws -> URL {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                let downloadedURL = try await performSingleDownload(from: url, to: destinationURL)
                
                // Verify the file
                try validateDownloadedFile(at: downloadedURL, filename: filename)
                
                print("FileDownloadService: File downloaded successfully to: \(downloadedURL.path)")
                return downloadedURL
                
            } catch let error as URLError {
                lastError = error
                
                // Check if we should retry
                if shouldRetryDownload(for: error) && attempt < maxRetries - 1 {
                    let delay = Double(1 << attempt) // Exponential backoff
                    print("FileDownloadService: Download attempt \(attempt + 1) failed, retrying in \(delay) seconds")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                
                throw error
                
            } catch {
                lastError = error
                throw error
            }
        }
        
        throw lastError ?? FileDownloadError.maxRetriesExceeded
    }
    
    private func performSingleDownload(from url: URL, to destinationURL: URL) async throws -> URL {
        var request = URLRequest(url: url)
        request.timeoutInterval = 60
        
        let (downloadURL, response) = try await urlSession.download(for: request)
        
        // Validate HTTP response
        if let httpResponse = response as? HTTPURLResponse {
            try validateHTTPResponse(httpResponse)
        }
        
        // Move file to destination
        try fileManager.moveItem(at: downloadURL, to: destinationURL)
        
        return destinationURL
    }
    
    private func validateHTTPResponse(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200:
            break // Success
        case 401, 403:
            throw FileDownloadError.authenticationError
        case 404:
            throw FileDownloadError.fileNotFound
        case 400...499:
            throw FileDownloadError.clientError(response.statusCode)
        case 500...599:
            throw FileDownloadError.serverError(response.statusCode)
        default:
            throw FileDownloadError.unexpectedResponse(response.statusCode)
        }
    }
    
    private func validateDownloadedFile(at url: URL, filename: String) throws {
        guard fileManager.fileExists(atPath: url.path) else {
            throw FileDownloadError.fileNotFound
        }
        
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int,
              fileSize > 0 else {
            throw FileDownloadError.emptyFile
        }
        
        print("FileDownloadService: Downloaded file '\(filename)' - Size: \(fileSize) bytes")
    }
    
    private func shouldRetryDownload(for error: URLError) -> Bool {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost:
            return true
        default:
            return false
        }
    }
}

// MARK: - File Download Error Types

enum FileDownloadError: Error {
    case invalidDownloadURL
    case authenticationError
    case fileNotFound
    case emptyFile
    case clientError(Int)
    case serverError(Int)
    case unexpectedResponse(Int)
    case maxRetriesExceeded
    
    var localizedDescription: String {
        switch self {
        case .invalidDownloadURL:
            return "Invalid download URL"
        case .authenticationError:
            return "Authentication failed"
        case .fileNotFound:
            return "File not found on server"
        case .emptyFile:
            return "Downloaded file is empty"
        case .clientError(let code):
            return "Client error: \(code)"
        case .serverError(let code):
            return "Server error: \(code)"
        case .unexpectedResponse(let code):
            return "Unexpected response: \(code)"
        case .maxRetriesExceeded:
            return "Maximum download retries exceeded"
        }
    }
} 