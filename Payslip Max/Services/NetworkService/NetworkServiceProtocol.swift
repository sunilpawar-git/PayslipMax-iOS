import Foundation

/// Protocol defining the network service interface
protocol NetworkServiceProtocol {
    /// Performs a GET request to the specified URL
    /// - Parameters:
    ///   - url: The URL to perform the GET request on
    ///   - completion: Completion handler with the result
    func get(from url: URL, completion: @escaping (Result<Data, NetworkError>) -> Void)
    
    /// Performs a GET request to the specified URL string
    /// - Parameters:
    ///   - urlString: The URL string to perform the GET request on
    ///   - completion: Completion handler with the result
    func get(from urlString: String, completion: @escaping (Result<Data, NetworkError>) -> Void)
    
    /// Performs a POST request to the specified URL
    /// - Parameters:
    ///   - url: The URL to perform the POST request on
    ///   - body: The body data to send with the request
    ///   - completion: Completion handler with the result
    func post(to url: URL, body: Data, completion: @escaping (Result<Data, NetworkError>) -> Void)
    
    /// Performs a POST request to the specified URL string
    /// - Parameters:
    ///   - urlString: The URL string to perform the POST request on
    ///   - body: The body data to send with the request
    ///   - completion: Completion handler with the result
    func post(to urlString: String, body: Data, completion: @escaping (Result<Data, NetworkError>) -> Void)
    
    /// Performs a PUT request to the specified URL
    /// - Parameters:
    ///   - url: The URL to perform the PUT request on
    ///   - body: The body data to send with the request
    ///   - completion: Completion handler with the result
    func put(to url: URL, body: Data, completion: @escaping (Result<Data, NetworkError>) -> Void)
    
    /// Performs a PUT request to the specified URL string
    /// - Parameters:
    ///   - urlString: The URL string to perform the PUT request on
    ///   - body: The body data to send with the request
    ///   - completion: Completion handler with the result
    func put(to urlString: String, body: Data, completion: @escaping (Result<Data, NetworkError>) -> Void)
    
    /// Performs a DELETE request to the specified URL
    /// - Parameters:
    ///   - url: The URL to perform the DELETE request on
    ///   - completion: Completion handler with the result
    func delete(at url: URL, completion: @escaping (Result<Data, NetworkError>) -> Void)
    
    /// Performs a DELETE request to the specified URL string
    /// - Parameters:
    ///   - urlString: The URL string to perform the DELETE request on
    ///   - completion: Completion handler with the result
    func delete(at urlString: String, completion: @escaping (Result<Data, NetworkError>) -> Void)
    
    /// Uploads a file to the specified URL
    /// - Parameters:
    ///   - fileURL: The local URL of the file to upload
    ///   - url: The URL to upload the file to
    ///   - completion: Completion handler with the result
    func uploadFile(from fileURL: URL, to url: URL, completion: @escaping (Result<Data, NetworkError>) -> Void)
    
    /// Downloads a file from the specified URL
    /// - Parameters:
    ///   - url: The URL to download the file from
    ///   - destinationURL: The local URL to save the downloaded file to
    ///   - completion: Completion handler with the result
    func downloadFile(from url: URL, to destinationURL: URL, completion: @escaping (Result<URL, NetworkError>) -> Void)
} 