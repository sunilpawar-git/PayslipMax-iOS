import Foundation

/// Basic implementation of NetworkServiceProtocol using URLSession
class BasicNetworkService: NetworkServiceProtocol {
    /// URLSession for network requests
    private let session: URLSession
    
    /// Default timeout interval for requests
    private let timeoutInterval: TimeInterval = 30.0
    
    /// Initializes a new network service
    /// - Parameter session: URLSession to use (defaults to shared session)
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    /// Performs a GET request
    /// - Parameters:
    ///   - endpoint: The API endpoint to request
    ///   - headers: Optional HTTP headers
    /// - Returns: Data from the response
    func get(from endpoint: String, headers: [String: String]? = nil) async throws -> Data {
        let url = try createURL(from: endpoint)
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = "GET"
        addHeaders(headers, to: &request)
        
        return try await performRequest(request)
    }
    
    /// Performs a POST request
    /// - Parameters:
    ///   - endpoint: The API endpoint to request
    ///   - body: The body data to send
    ///   - headers: Optional HTTP headers
    /// - Returns: Data from the response
    func post(to endpoint: String, body: Data, headers: [String: String]? = nil) async throws -> Data {
        let url = try createURL(from: endpoint)
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = "POST"
        request.httpBody = body
        addHeaders(headers, to: &request)
        
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        return try await performRequest(request)
    }
    
    /// Performs a PUT request
    /// - Parameters:
    ///   - endpoint: The API endpoint to request
    ///   - body: The body data to send
    ///   - headers: Optional HTTP headers
    /// - Returns: Data from the response
    func put(to endpoint: String, body: Data, headers: [String: String]? = nil) async throws -> Data {
        let url = try createURL(from: endpoint)
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = "PUT"
        request.httpBody = body
        addHeaders(headers, to: &request)
        
        if request.value(forHTTPHeaderField: "Content-Type") == nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        
        return try await performRequest(request)
    }
    
    /// Performs a DELETE request
    /// - Parameters:
    ///   - endpoint: The API endpoint to request
    ///   - headers: Optional HTTP headers
    /// - Returns: Data from the response
    func delete(from endpoint: String, headers: [String: String]? = nil) async throws -> Data {
        let url = try createURL(from: endpoint)
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = "DELETE"
        addHeaders(headers, to: &request)
        
        return try await performRequest(request)
    }
    
    /// Uploads a file
    /// - Parameters:
    ///   - fileURL: The URL of the file to upload
    ///   - endpoint: The API endpoint to upload to
    ///   - headers: Optional HTTP headers
    /// - Returns: Data from the response
    func uploadFile(from fileURL: URL, to endpoint: String, headers: [String: String]? = nil) async throws -> Data {
        let url = try createURL(from: endpoint)
        
        // Create a boundary string for multipart form data
        let boundary = UUID().uuidString
        
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = "POST"
        addHeaders(headers, to: &request)
        
        // Set content type for multipart form data
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Create multipart form data
        let fileData = try Data(contentsOf: fileURL)
        let fileName = fileURL.lastPathComponent
        let mimeType = mimeTypeForPath(fileURL.path)
        
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        return try await performRequest(request)
    }
    
    /// Downloads a file
    /// - Parameters:
    ///   - endpoint: The API endpoint to download from
    ///   - destination: The URL where the file should be saved
    ///   - headers: Optional HTTP headers
    /// - Returns: The URL where the file was saved
    func downloadFile(from endpoint: String, to destination: URL, headers: [String: String]? = nil) async throws -> URL {
        let url = try createURL(from: endpoint)
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = "GET"
        addHeaders(headers, to: &request)
        
        let (downloadURL, response) = try await session.download(for: request)
        
        // Check response status code
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        // Create directory if it doesn't exist
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        
        // Remove existing file if it exists
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        
        // Move downloaded file to destination
        try FileManager.default.moveItem(at: downloadURL, to: destination)
        
        return destination
    }
    
    // MARK: - Private Helper Methods
    
    /// Creates a URL from an endpoint string
    /// - Parameter endpoint: The endpoint string
    /// - Returns: A URL
    private func createURL(from endpoint: String) throws -> URL {
        let urlString: String
        
        // Check if the endpoint is already a full URL
        if endpoint.lowercased().hasPrefix("http") {
            urlString = endpoint
        } else {
            // Otherwise, prepend the base URL
            urlString = APIEndpoints.url(for: endpoint)
        }
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        return url
    }
    
    /// Adds headers to a URLRequest
    /// - Parameters:
    ///   - headers: Headers to add
    ///   - request: The request to modify
    private func addHeaders(_ headers: [String: String]?, to request: inout URLRequest) {
        // Add default headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add custom headers
        headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
    
    /// Performs a URLRequest and handles the response
    /// - Parameter request: The request to perform
    /// - Returns: Data from the response
    private func performRequest(_ request: URLRequest) async throws -> Data {
        do {
            let (data, response) = try await session.data(for: request)
            
            // Check response status code
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                return data
            case 401:
                throw NetworkError.unauthorized
            default:
                throw NetworkError.serverError(httpResponse.statusCode)
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.requestFailed(error)
        }
    }
    
    /// Determines the MIME type for a file path
    /// - Parameter path: The file path
    /// - Returns: The MIME type string
    private func mimeTypeForPath(_ path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let pathExtension = url.pathExtension
        
        switch pathExtension.lowercased() {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "pdf":
            return "application/pdf"
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "xls":
            return "application/vnd.ms-excel"
        case "xlsx":
            return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "txt":
            return "text/plain"
        case "json":
            return "application/json"
        default:
            return "application/octet-stream"
        }
    }
} 