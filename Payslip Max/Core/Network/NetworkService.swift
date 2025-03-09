import Foundation
import Combine

// MARK: - Network Service Protocol

/// Protocol defining the requirements for a network service.
protocol NetworkServiceProtocol {
    /// Performs a network request.
    ///
    /// - Parameters:
    ///   - request: The request to perform.
    /// - Returns: A publisher that emits the response data or an error.
    func request<T: Decodable>(_ request: NetworkRequest) -> AnyPublisher<T, Error>
    
    /// Performs a network request with a custom response type.
    ///
    /// - Parameters:
    ///   - request: The request to perform.
    ///   - type: The type to decode the response as.
    /// - Returns: A publisher that emits the decoded response or an error.
    func request<T: Decodable>(_ request: NetworkRequest, as type: T.Type) -> AnyPublisher<T, Error>
    
    /// Performs a network request that returns raw data.
    ///
    /// - Parameters:
    ///   - request: The request to perform.
    /// - Returns: A publisher that emits the response data or an error.
    func requestData(_ request: NetworkRequest) -> AnyPublisher<Data, Error>
    
    /// Uploads data to a server.
    ///
    /// - Parameters:
    ///   - data: The data to upload.
    ///   - request: The request to perform.
    /// - Returns: A publisher that emits the response data or an error.
    func upload<T: Decodable>(data: Data, with request: NetworkRequest) -> AnyPublisher<T, Error>
    
    /// Downloads data from a server.
    ///
    /// - Parameters:
    ///   - request: The request to perform.
    /// - Returns: A publisher that emits the downloaded data or an error.
    func download(_ request: NetworkRequest) -> AnyPublisher<Data, Error>
}

// MARK: - Network Request

/// A struct representing a network request.
struct NetworkRequest {
    /// The HTTP method for the request.
    enum Method: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case patch = "PATCH"
    }
    
    /// The URL for the request.
    let url: URL
    
    /// The HTTP method for the request.
    let method: Method
    
    /// The headers for the request.
    let headers: [String: String]
    
    /// The query parameters for the request.
    let queryParameters: [String: String]
    
    /// The body parameters for the request.
    let bodyParameters: [String: Any]?
    
    /// The timeout interval for the request.
    let timeoutInterval: TimeInterval
    
    /// Initializes a new network request.
    ///
    /// - Parameters:
    ///   - url: The URL for the request.
    ///   - method: The HTTP method for the request.
    ///   - headers: The headers for the request.
    ///   - queryParameters: The query parameters for the request.
    ///   - bodyParameters: The body parameters for the request.
    ///   - timeoutInterval: The timeout interval for the request.
    init(
        url: URL,
        method: Method = .get,
        headers: [String: String] = [:],
        queryParameters: [String: String] = [:],
        bodyParameters: [String: Any]? = nil,
        timeoutInterval: TimeInterval = 30.0
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.queryParameters = queryParameters
        self.bodyParameters = bodyParameters
        self.timeoutInterval = timeoutInterval
    }
    
    /// Creates a URLRequest from the network request.
    ///
    /// - Returns: A URLRequest.
    func asURLRequest() -> URLRequest {
        // Create URL with query parameters
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        
        if !queryParameters.isEmpty {
            urlComponents.queryItems = queryParameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeoutInterval
        
        // Add headers
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        // Add body parameters
        if let bodyParameters = bodyParameters {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: bodyParameters, options: [])
                
                // Add content-type header if not already present
                if request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                }
            } catch {
                ErrorLogger.log(error)
            }
        }
        
        return request
    }
}

// MARK: - Network Service Implementation

/// Default implementation of the NetworkServiceProtocol.
class NetworkService: NetworkServiceProtocol {
    /// The URL session to use for network requests.
    private let session: URLSession
    
    /// The JSON decoder to use for decoding responses.
    private let decoder: JSONDecoder
    
    /// Initializes a new network service.
    ///
    /// - Parameters:
    ///   - session: The URL session to use for network requests.
    ///   - decoder: The JSON decoder to use for decoding responses.
    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
        
        // Configure the decoder
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    /// Performs a network request.
    ///
    /// - Parameters:
    ///   - request: The request to perform.
    /// - Returns: A publisher that emits the response data or an error.
    func request<T: Decodable>(_ request: NetworkRequest) -> AnyPublisher<T, Error> {
        return request(request, as: T.self)
    }
    
    /// Performs a network request with a custom response type.
    ///
    /// - Parameters:
    ///   - request: The request to perform.
    ///   - type: The type to decode the response as.
    /// - Returns: A publisher that emits the decoded response or an error.
    func request<T: Decodable>(_ request: NetworkRequest, as type: T.Type) -> AnyPublisher<T, Error> {
        return requestData(request)
            .decode(type: T.self, decoder: decoder)
            .mapError { error in
                if error is DecodingError {
                    return AppError.invalidResponse
                }
                return error
            }
            .eraseToAnyPublisher()
    }
    
    /// Performs a network request that returns raw data.
    ///
    /// - Parameters:
    ///   - request: The request to perform.
    /// - Returns: A publisher that emits the response data or an error.
    func requestData(_ request: NetworkRequest) -> AnyPublisher<Data, Error> {
        return session.dataTaskPublisher(for: request.asURLRequest())
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AppError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw AppError.authenticationFailed("Unauthorized")
                case 403:
                    throw AppError.authenticationFailed("Forbidden")
                case 404:
                    throw AppError.requestFailed(httpResponse.statusCode)
                case 500...599:
                    throw AppError.serverError("Server error with status code: \(httpResponse.statusCode)")
                default:
                    throw AppError.requestFailed(httpResponse.statusCode)
                }
            }
            .mapError { error in
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet:
                        return AppError.networkConnectionLost
                    case .timedOut:
                        return AppError.timeoutError
                    default:
                        return AppError.unknown(error)
                    }
                }
                return error
            }
            .eraseToAnyPublisher()
    }
    
    /// Uploads data to a server.
    ///
    /// - Parameters:
    ///   - data: The data to upload.
    ///   - request: The request to perform.
    /// - Returns: A publisher that emits the response data or an error.
    func upload<T: Decodable>(data: Data, with request: NetworkRequest) -> AnyPublisher<T, Error> {
        var urlRequest = request.asURLRequest()
        
        // Create a multipart/form-data request
        let boundary = "Boundary-\(UUID().uuidString)"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Create the body
        var body = Data()
        
        // Add the file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"file.pdf\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add the end boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Set the body
        urlRequest.httpBody = body
        
        return session.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw AppError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 401:
                    throw AppError.authenticationFailed("Unauthorized")
                case 403:
                    throw AppError.authenticationFailed("Forbidden")
                case 404:
                    throw AppError.requestFailed(httpResponse.statusCode)
                case 500...599:
                    throw AppError.serverError("Server error with status code: \(httpResponse.statusCode)")
                default:
                    throw AppError.requestFailed(httpResponse.statusCode)
                }
            }
            .decode(type: T.self, decoder: decoder)
            .mapError { error in
                if error is DecodingError {
                    return AppError.invalidResponse
                }
                return error
            }
            .eraseToAnyPublisher()
    }
    
    /// Downloads data from a server.
    ///
    /// - Parameters:
    ///   - request: The request to perform.
    /// - Returns: A publisher that emits the downloaded data or an error.
    func download(_ request: NetworkRequest) -> AnyPublisher<Data, Error> {
        return requestData(request)
    }
}

// MARK: - Data Extensions

extension Data {
    /// Appends a string to the data.
    ///
    /// - Parameter string: The string to append.
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
} 