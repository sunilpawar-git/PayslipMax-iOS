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


// MARK: - Network Service Implementation

/// Default implementation of the NetworkServiceProtocol.
class NetworkService: NetworkServiceProtocol {

    // MARK: - Dependencies

    /// The URL session to use for network requests.
    private let session: URLSession

    /// The JSON decoder to use for decoding responses.
    private let decoder: JSONDecoder

    /// Service for handling network response validation and error mapping.
    private let responseHandler: NetworkResponseHandlerProtocol

    /// Service for handling multipart form data uploads.
    private let uploadService: NetworkUploadServiceProtocol

    /// Initializes a new network service.
    ///
    /// - Parameters:
    ///   - session: The URL session to use for network requests.
    ///   - decoder: The JSON decoder to use for decoding responses.
    ///   - responseHandler: Service for handling response validation and errors.
    ///   - uploadService: Service for handling multipart uploads.
    init(
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder(),
        responseHandler: NetworkResponseHandlerProtocol = NetworkResponseHandler(),
        uploadService: NetworkUploadServiceProtocol = NetworkUploadService()
    ) {
        self.session = session
        self.decoder = decoder
        self.responseHandler = responseHandler
        self.uploadService = uploadService

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
        return self.request(request, as: T.self)
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
                try self.responseHandler.validateResponse(data, response: response)
            }
            .mapError { error in
                if let urlError = error as? URLError {
                    return self.responseHandler.mapURLError(urlError)
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
        let urlRequest = uploadService.createMultipartRequest(with: data, request: request)

        return session.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response in
                try self.responseHandler.validateResponse(data, response: response)
            }
            .decode(type: T.self, decoder: decoder)
            .mapError { error in
                if error is DecodingError {
                    return AppError.invalidResponse
                }
                if let urlError = error as? URLError {
                    return self.responseHandler.mapURLError(urlError)
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
