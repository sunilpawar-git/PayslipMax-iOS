import Foundation

/// Protocol for handling deep links
protocol DeepLinkHandlerProtocol {
    /// Process a URL received from a deep link
    func processURL(_ url: URL) -> Bool

    /// Process Universal Link from the website
    func processUniversalLink(_ url: URL) -> Bool
}

/// Implementation of the deep link handler
class WebUploadDeepLinkHandler: DeepLinkHandlerProtocol {
    private let webUploadService: WebUploadServiceProtocol

    init(webUploadService: WebUploadServiceProtocol) {
        self.webUploadService = webUploadService
    }

    func processURL(_ url: URL) -> Bool {
        print("WebUploadDeepLinkHandler.processURL called with: \(url.absoluteString)")

        guard url.scheme == "payslipmax" else {
            print("WebUploadDeepLinkHandler: Not a payslipmax:// URL")
            return false
        }

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            print("WebUploadDeepLinkHandler: Failed to create URLComponents")
            return false
        }

        let host = components.host
        print("WebUploadDeepLinkHandler: URL host is: \(host ?? "nil")")

        switch host {
        case "upload":
            return handleUploadURL(components)
        case "process":
            return handleProcessURL(components)
        default:
            print("WebUploadDeepLinkHandler: Unrecognized host: \(host ?? "nil")")
            return false
        }
    }

    func processUniversalLink(_ url: URL) -> Bool {
        guard url.host == "payslipmax.com" || url.host == "www.payslipmax.com" else {
            return false
        }

        let pathComponents = url.pathComponents

        if pathComponents.count >= 2 && pathComponents[1] == "upload" {
            guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                return false
            }
            return handleUploadURL(components)
        }

        return false
    }

    // MARK: - Upload URL Handling

    private func handleUploadURL(_ components: URLComponents) -> Bool {
        guard let queryItems = components.queryItems else {
            print("WebUploadDeepLinkHandler: Missing query items")
            return false
        }

        print("WebUploadDeepLinkHandler: Received query items: \(queryItems)")

        guard let uploadInfo = parseUploadInfo(from: queryItems) else {
            return false
        }

        print("WebUploadDeepLinkHandler: Starting download for ID: \(uploadInfo.stringID ?? uploadInfo.id.uuidString)")
        startDownloadTask(for: uploadInfo)

        return true
    }

    private func parseUploadInfo(from queryItems: [URLQueryItem]) -> WebUploadInfo? {
        guard let idString = queryItems.first(where: { $0.name == "id" })?.value,
              let filename = queryItems.first(where: { $0.name == "filename" })?.value,
              let sizeString = queryItems.first(where: { $0.name == "size" })?.value,
              let size = Int(sizeString) else {
            print("WebUploadDeepLinkHandler: Missing required parameters (id, filename, size)")
            return nil
        }

        let (token, isProtected) = extractTokenAndProtection(from: queryItems, filename: filename)

        guard let token = token else {
            print("WebUploadDeepLinkHandler: No token or hash found - cannot proceed")
            return nil
        }

        print("WebUploadDeepLinkHandler: Processing upload - ID: \(idString), Filename: \(filename), Protected: \(isProtected)")

        return WebUploadInfo(
            stringID: idString,
            filename: filename,
            uploadedAt: Date(),
            fileSize: size,
            isPasswordProtected: isProtected,
            source: "web",
            status: .pending,
            secureToken: token
        )
    }

    private func extractTokenAndProtection(from queryItems: [URLQueryItem], filename: String) -> (String?, Bool) {
        let hasToken = queryItems.first(where: { $0.name == "token" })?.value != nil
        let hasHash = queryItems.first(where: { $0.name == "hash" })?.value != nil

        if hasToken {
            guard let tokenValue = queryItems.first(where: { $0.name == "token" })?.value else {
                print("WebUploadDeepLinkHandler: Missing token parameter in new format")
                return (nil, false)
            }

            var isProtected = false
            if let protectedString = queryItems.first(where: { $0.name == "protected" })?.value {
                isProtected = Bool(protectedString) ?? false
            }

            print("WebUploadDeepLinkHandler: Using new format with token")
            return (tokenValue, isProtected)
        } else if hasHash {
            guard let hashValue = queryItems.first(where: { $0.name == "hash" })?.value else {
                print("WebUploadDeepLinkHandler: Missing hash parameter in old format")
                return (nil, false)
            }

            let lowercaseFilename = filename.lowercased()
            let isProtected = lowercaseFilename.contains("password") || lowercaseFilename.contains("protected")

            print("WebUploadDeepLinkHandler: Using old format with hash as token")
            return (hashValue, isProtected)
        }

        return (nil, false)
    }

    private func startDownloadTask(for uploadInfo: WebUploadInfo) {
        Task {
            do {
                let downloadedURL = try await webUploadService.downloadFile(from: uploadInfo)
                try await processDownloadedFile(at: downloadedURL, uploadInfo: uploadInfo)
            } catch {
                print("WebUploadDeepLinkHandler: Failed to process upload: \(error)")
            }
        }
    }

    private func processDownloadedFile(at url: URL, uploadInfo: WebUploadInfo) async throws {
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("WebUploadDeepLinkHandler: File doesn't exist after download at \(url.path)")
            throw NSError(domain: "WebUploadErrorDomain", code: 3, userInfo: [NSLocalizedDescriptionKey: "File not found after download"])
        }

        let pendingUploads = await webUploadService.getPendingUploads()

        guard let updatedUploadInfo = findUploadInfo(in: pendingUploads, matching: uploadInfo) else {
            print("WebUploadDeepLinkHandler: Could not find updated upload info after download")
            throw NSError(domain: "WebUploadErrorDomain", code: 5, userInfo: [NSLocalizedDescriptionKey: "File not found in uploads list"])
        }

        guard let localURL = updatedUploadInfo.localURL,
              FileManager.default.fileExists(atPath: localURL.path) else {
            print("WebUploadDeepLinkHandler: Local URL is missing or file doesn't exist")
            throw NSError(domain: "WebUploadErrorDomain", code: 4, userInfo: [NSLocalizedDescriptionKey: "Local file doesn't exist"])
        }

        print("WebUploadDeepLinkHandler: File downloaded to \(localURL.path)")

        if !uploadInfo.isPasswordProtected {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            try await webUploadService.processDownloadedFile(uploadInfo: updatedUploadInfo, password: nil)
        }
    }

    private func findUploadInfo(in uploads: [WebUploadInfo], matching uploadInfo: WebUploadInfo) -> WebUploadInfo? {
        let idString = uploadInfo.stringID
        return uploads.first { upload in
            upload.id == uploadInfo.id || (upload.stringID != nil && upload.stringID == idString)
        }
    }

    // MARK: - Process URL Handling

    private func handleProcessURL(_ components: URLComponents) -> Bool {
        guard let queryItems = components.queryItems,
              let idString = queryItems.first(where: { $0.name == "id" })?.value,
              let id = UUID(uuidString: idString) else {
            return false
        }

        let password = queryItems.first(where: { $0.name == "password" })?.value

        if let password = password {
            do {
                try webUploadService.savePassword(for: id, password: password)
            } catch {
                print("Failed to save password: \(error)")
                return false
            }
        }

        startProcessTask(for: id, password: password)
        return true
    }

    private func startProcessTask(for id: UUID, password: String?) {
        Task {
            do {
                let pendingUploads = await webUploadService.getPendingUploads()

                guard let upload = pendingUploads.first(where: { $0.id == id }) else {
                    return
                }

                let storedPassword = password ?? webUploadService.getPassword(for: id)
                try await webUploadService.processDownloadedFile(uploadInfo: upload, password: storedPassword)
            } catch {
                print("Failed to process upload: \(error)")
            }
        }
    }
}
