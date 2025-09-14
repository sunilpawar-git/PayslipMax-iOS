import Foundation

/// Service responsible for handling multipart form data uploads
protocol NetworkUploadServiceProtocol {
    func createMultipartRequest(with data: Data, request: NetworkRequest) -> URLRequest
}

/// Service responsible for handling multipart form data uploads
class NetworkUploadService: NetworkUploadServiceProtocol {

    /// Creates a multipart/form-data URLRequest for file upload
    func createMultipartRequest(with data: Data, request: NetworkRequest) -> URLRequest {
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

        return urlRequest
    }
}
