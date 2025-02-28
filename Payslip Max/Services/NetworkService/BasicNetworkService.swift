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
    
    // MARK: - NetworkServiceProtocol Implementation
    
    /// Performs a GET request to the specified URL
    /// - Parameters:
    ///   - url: The URL to perform the GET request on
    ///   - completion: Completion handler with the result
    func get(from url: URL, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        let request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        performDataTask(with: request, completion: completion)
    }
    
    /// Performs a GET request to the specified URL string
    /// - Parameters:
    ///   - urlString: The URL string to perform the GET request on
    ///   - completion: Completion handler with the result
    func get(from urlString: String, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        get(from: url, completion: completion)
    }
    
    /// Performs a POST request to the specified URL
    /// - Parameters:
    ///   - url: The URL to perform the POST request on
    ///   - body: The body data to send with the request
    ///   - completion: Completion handler with the result
    func post(to url: URL, body: Data, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        performDataTask(with: request, completion: completion)
    }
    
    /// Performs a POST request to the specified URL string
    /// - Parameters:
    ///   - urlString: The URL string to perform the POST request on
    ///   - body: The body data to send with the request
    ///   - completion: Completion handler with the result
    func post(to urlString: String, body: Data, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        post(to: url, body: body, completion: completion)
    }
    
    /// Performs a PUT request to the specified URL
    /// - Parameters:
    ///   - url: The URL to perform the PUT request on
    ///   - body: The body data to send with the request
    ///   - completion: Completion handler with the result
    func put(to url: URL, body: Data, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = "PUT"
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        performDataTask(with: request, completion: completion)
    }
    
    /// Performs a PUT request to the specified URL string
    /// - Parameters:
    ///   - urlString: The URL string to perform the PUT request on
    ///   - body: The body data to send with the request
    ///   - completion: Completion handler with the result
    func put(to urlString: String, body: Data, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        put(to: url, body: body, completion: completion)
    }
    
    /// Performs a DELETE request to the specified URL
    /// - Parameters:
    ///   - url: The URL to perform the DELETE request on
    ///   - completion: Completion handler with the result
    func delete(at url: URL, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = "DELETE"
        performDataTask(with: request, completion: completion)
    }
    
    /// Performs a DELETE request to the specified URL string
    /// - Parameters:
    ///   - urlString: The URL string to perform the DELETE request on
    ///   - completion: Completion handler with the result
    func delete(at urlString: String, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }
        delete(at: url, completion: completion)
    }
    
    /// Uploads a file to the specified URL
    /// - Parameters:
    ///   - fileURL: The local URL of the file to upload
    ///   - url: The URL to upload the file to
    ///   - completion: Completion handler with the result
    func uploadFile(from fileURL: URL, to url: URL, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        do {
            let data = try Data(contentsOf: fileURL)
            
            var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
            request.httpMethod = "POST"
            request.httpBody = data
            request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
            
            performDataTask(with: request, completion: completion)
        } catch {
            completion(.failure(.fileOperationFailed(error)))
        }
    }
    
    /// Downloads a file from the specified URL
    /// - Parameters:
    ///   - url: The URL to download the file from
    ///   - destinationURL: The local URL to save the downloaded file to
    ///   - completion: Completion handler with the result
    func downloadFile(from url: URL, to destinationURL: URL, completion: @escaping (Result<URL, NetworkError>) -> Void) {
        let task = session.downloadTask(with: url) { tempURL, response, error in
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                completion(.failure(.serverError(httpResponse.statusCode)))
                return
            }
            
            guard let tempURL = tempURL else {
                completion(.failure(.noData))
                return
            }
            
            do {
                // Create directory if it doesn't exist
                try FileManager.default.createDirectory(
                    at: destinationURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                
                // Remove existing file if it exists
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                
                // Move downloaded file to destination
                try FileManager.default.moveItem(at: tempURL, to: destinationURL)
                
                completion(.success(destinationURL))
            } catch {
                completion(.failure(.fileOperationFailed(error)))
            }
        }
        
        task.resume()
    }
    
    // MARK: - Legacy Async/Await Methods
    
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
    
    // MARK: - Private Helper Methods
    
    /// Performs a data task with the given request
    /// - Parameters:
    ///   - request: The request to perform
    ///   - completion: Completion handler with the result
    private func performDataTask(with request: URLRequest, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.requestFailed(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                completion(.failure(.serverError(httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            completion(.success(data))
        }
        
        task.resume()
    }
    
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