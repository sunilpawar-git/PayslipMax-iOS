import Foundation

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
