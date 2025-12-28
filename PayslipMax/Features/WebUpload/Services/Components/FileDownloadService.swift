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

        let downloadEndpoint = try buildDownloadURL(for: uploadInfo)
        let destinationURL = directory.appendingPathComponent(uploadInfo.filename)

        try prepareDestination(at: destinationURL)

        return try await performDownloadWithRetry(
            from: downloadEndpoint,
            to: destinationURL
        )
    }

    // MARK: - Private Helpers

    private func buildDownloadURL(for uploadInfo: WebUploadInfo) throws -> URL {
        var components = URLComponents(url: baseURL.appendingPathComponent("download"), resolvingAgainstBaseURL: true)!
        let idParameter = uploadInfo.stringID ?? uploadInfo.id.uuidString

        components.queryItems = [URLQueryItem(name: "id", value: idParameter)]

        if let token = uploadInfo.secureToken {
            components.queryItems?.append(URLQueryItem(name: "token", value: token))
        }

        guard let url = components.url else {
            print("FileDownloadService: Failed to create download URL")
            throw NSError(domain: "WebUploadErrorDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Invalid download URL"])
        }

        print("FileDownloadService: Downloading from URL: \(url.absoluteString)")
        return url
    }

    private func prepareDestination(at url: URL) throws {
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    private func performDownloadWithRetry(from endpoint: URL, to destination: URL) async throws -> URL {
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 60

        var retryCount = 0
        var lastError: Error?

        while retryCount < maxRetries {
            do {
                return try await attemptDownload(request: request, to: destination)
            } catch let error as URLError {
                lastError = error
                retryCount += 1
                print("FileDownloadService: Download attempt \(retryCount) failed with URLError: \(error.localizedDescription)")

                let shouldRetry = isRetryableError(error) && retryCount < maxRetries
                if !shouldRetry {
                    throw buildUserFriendlyError(from: error, attempts: retryCount)
                }

                try await waitForRetry(attempt: retryCount)
            } catch {
                print("FileDownloadService: Download failed with non-network error: \(error)")
                throw error
            }
        }

        if let lastError = lastError {
            throw lastError
        }
        throw NSError(domain: "WebUploadErrorDomain", code: 1007, userInfo: [NSLocalizedDescriptionKey: "Download failed after \(maxRetries) attempts"])
    }

    private func attemptDownload(request: URLRequest, to destination: URL) async throws -> URL {
        let (downloadURL, response) = try await urlSession.download(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            print("FileDownloadService: Received HTTP response code: \(httpResponse.statusCode)")
            try validateHTTPResponse(httpResponse)
        }

        try fileManager.moveItem(at: downloadURL, to: destination)
        print("FileDownloadService: File downloaded successfully to: \(destination.path)")

        try validateDownloadedFile(at: destination)
        return destination
    }

    private func validateHTTPResponse(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200:
            return
        case 401, 403:
            throw NSError(domain: "WebUploadErrorDomain", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: "Authentication error: Not authorized to download this file"])
        case 404:
            throw NSError(domain: "WebUploadErrorDomain", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: "File not found on server"])
        case 400...499:
            throw NSError(domain: "WebUploadErrorDomain", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: "Download failed - client error: \(response.statusCode)"])
        case 500...599:
            print("FileDownloadService: Server error \(response.statusCode) - will retry")
            throw NSError(domain: "WebUploadErrorDomain", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error \(response.statusCode)"])
        default:
            print("FileDownloadService: Unexpected status code \(response.statusCode)")
            throw NSError(domain: "WebUploadErrorDomain", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unexpected response: \(response.statusCode)"])
        }
    }

    private func validateDownloadedFile(at url: URL) throws {
        guard fileManager.fileExists(atPath: url.path),
              let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int,
              fileSize > 0 else {
            print("FileDownloadService: Downloaded file is invalid or empty")
            throw NSError(domain: "WebUploadErrorDomain", code: 1006, userInfo: [NSLocalizedDescriptionKey: "Downloaded file is invalid or empty"])
        }
    }

    private func isRetryableError(_ error: URLError) -> Bool {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .timedOut, .cannotConnectToHost:
            return true
        default:
            return false
        }
    }

    private func buildUserFriendlyError(from error: URLError, attempts: Int) -> NSError {
        print("FileDownloadService: Giving up after \(attempts) attempts")

        let message: String
        switch error.code {
        case .notConnectedToInternet:
            message = "No internet connection. Please check your network and try again."
        case .timedOut:
            message = "Download timed out. The file may be too large or the server is busy."
        case .cannotFindHost, .cannotConnectToHost:
            message = "Cannot connect to server. Please verify the API is available."
        case .networkConnectionLost:
            message = "Network connection was lost during download."
        default:
            message = "Download failed: \(error.localizedDescription)"
        }

        return NSError(domain: "WebUploadErrorDomain", code: error.code.rawValue, userInfo: [NSLocalizedDescriptionKey: message])
    }

    private func waitForRetry(attempt: Int) async throws {
        let waitTime = TimeInterval(pow(2.0, Double(attempt - 1)))
        print("FileDownloadService: Waiting \(waitTime) seconds before retry...")
        try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
    }
}
