import Foundation

/// Protocol defining validation functionality for web uploads
protocol WebUploadValidationServiceProtocol {
    func validateUploadInfo(_ uploadInfo: WebUploadInfo) throws
    func validateDownloadedFile(at url: URL, expectedSize: Int64?) throws
    func validateQRCodeData(_ data: String) throws -> WebUploadInfo
}

/// Service responsible for validating web upload data and operations
class WebUploadValidationService: WebUploadValidationServiceProtocol {
    // MARK: - Constants
    private static let maxFilenameLength = 255
    private static let maxFileSize: Int64 = 100 * 1024 * 1024 // 100MB
    private static let allowedFileExtensions = ["pdf"]
    
    // MARK: - Dependencies
    private let fileManager: FileManager
    
    // MARK: - Initialization
    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }
    
    // MARK: - Public Methods
    
    func validateUploadInfo(_ uploadInfo: WebUploadInfo) throws {
        // Validate filename
        try validateFilename(uploadInfo.filename)
        
        // Validate file size if provided (non-zero)
        if uploadInfo.fileSize > 0 {
            try validateFileSize(Int64(uploadInfo.fileSize))
        }
        
        // Validate upload status
        try validateUploadStatus(uploadInfo.status)
        
        // Validate timestamp
        try validateTimestamp(uploadInfo.uploadedAt)
        
        print("WebUploadValidationService: Upload info validation passed for: \(uploadInfo.filename)")
    }
    
    func validateDownloadedFile(at url: URL, expectedSize: Int64?) throws {
        // Check if file exists
        guard fileManager.fileExists(atPath: url.path) else {
            throw WebUploadValidationError.fileNotFound
        }
        
        // Get file attributes
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.path),
              let actualSize = attributes[.size] as? Int64 else {
            throw WebUploadValidationError.cannotReadFileAttributes
        }
        
        // Check file size
        guard actualSize > 0 else {
            throw WebUploadValidationError.emptyFile
        }
        
        guard actualSize <= Self.maxFileSize else {
            throw WebUploadValidationError.fileTooLarge(actualSize, Self.maxFileSize)
        }
        
        // Validate expected size if provided
        if let expectedSize = expectedSize {
            guard actualSize == expectedSize else {
                throw WebUploadValidationError.sizeMismatch(actual: actualSize, expected: expectedSize)
            }
        }
        
        // Validate file extension
        let fileExtension = url.pathExtension.lowercased()
        guard Self.allowedFileExtensions.contains(fileExtension) else {
            throw WebUploadValidationError.unsupportedFileType(fileExtension)
        }
        
        // Validate PDF header
        try validatePDFHeader(at: url)
        
        print("WebUploadValidationService: Downloaded file validation passed: \(url.lastPathComponent)")
    }
    
    func validateQRCodeData(_ data: String) throws -> WebUploadInfo {
        // Parse QR code data as URL
        guard let url = URL(string: data) else {
            throw WebUploadValidationError.invalidQRCodeFormat
        }
        
        // Validate scheme
        guard url.scheme == "payslipmax" else {
            throw WebUploadValidationError.invalidQRCodeScheme(url.scheme ?? "nil")
        }
        
        // Validate host
        guard url.host == "upload" else {
            throw WebUploadValidationError.invalidQRCodeHost(url.host ?? "nil")
        }
        
        // Parse query parameters
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            throw WebUploadValidationError.missingQRCodeParameters
        }
        
        // Extract required parameters
        let parameters = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item in
            item.value != nil ? (item.name, item.value!) : nil
        })
        
        // Validate required parameters
        guard let idString = parameters["id"],
              let filename = parameters["filename"] else {
            throw WebUploadValidationError.missingRequiredParameters
        }
        
        // Parse ID as UUID
        guard let id = UUID(uuidString: idString) else {
            throw WebUploadValidationError.invalidIDFormat(idString)
        }
        
        // Validate filename
        try validateFilename(filename)
        
        // Parse optional parameters
        let fileSize = parameters["size"].flatMap { Int64($0) }
        let timestamp = parameters["timestamp"].flatMap { TimeInterval($0) }.flatMap { Date(timeIntervalSince1970: $0) }
        let secureToken = parameters["hash"] // Using hash as secure token
        
        // Create WebUploadInfo
        let uploadInfo = WebUploadInfo(
            id: id,
            stringID: idString,
            filename: filename,
            uploadedAt: timestamp ?? Date(),
            fileSize: fileSize.map(Int.init) ?? 0,
            isPasswordProtected: parameters["password"] == "true",
            source: "payslipmax.com",
            status: .pending,
            secureToken: secureToken,
            localURL: nil
        )
        
        print("WebUploadValidationService: QR code validation passed for: \(filename)")
        return uploadInfo
    }
    
    // MARK: - Private Validation Methods
    
    private func validateFilename(_ filename: String) throws {
        guard !filename.isEmpty else {
            throw WebUploadValidationError.emptyFilename
        }
        
        guard filename.count <= Self.maxFilenameLength else {
            throw WebUploadValidationError.filenameTooLong(filename.count, Self.maxFilenameLength)
        }
        
        // Check for invalid characters
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
        guard filename.rangeOfCharacter(from: invalidCharacters) == nil else {
            throw WebUploadValidationError.invalidFilenameCharacters
        }
        
        // Validate file extension
        let fileExtension = (filename as NSString).pathExtension.lowercased()
        guard Self.allowedFileExtensions.contains(fileExtension) else {
            throw WebUploadValidationError.unsupportedFileType(fileExtension)
        }
    }
    
    private func validateFileSize(_ fileSize: Int64) throws {
        guard fileSize > 0 else {
            throw WebUploadValidationError.emptyFile
        }
        
        guard fileSize <= Self.maxFileSize else {
            throw WebUploadValidationError.fileTooLarge(fileSize, Self.maxFileSize)
        }
    }
    
    private func validateUploadStatus(_ status: UploadStatus) throws {
        // All UploadStatus cases are valid, no specific validation needed
        print("WebUploadValidationService: Upload status validation passed: \(status)")
    }
    
    private func validateTimestamp(_ timestamp: Date) throws {
        let now = Date()
        let maxAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
        let maxFuture: TimeInterval = 5 * 60 // 5 minutes
        
        if timestamp.addingTimeInterval(maxAge) < now {
            throw WebUploadValidationError.timestampTooOld(timestamp)
        }
        
        if timestamp.timeIntervalSince(now) > maxFuture {
            throw WebUploadValidationError.timestampInFuture(timestamp)
        }
    }
    
    private func validatePDFHeader(at url: URL) throws {
        guard let fileHandle = FileHandle(forReadingAtPath: url.path) else {
            throw WebUploadValidationError.cannotReadFile
        }
        
        defer {
            fileHandle.closeFile()
        }
        
        // Read first 5 bytes to check PDF header
        let headerData = fileHandle.readData(ofLength: 5)
        guard headerData.count >= 4 else {
            throw WebUploadValidationError.invalidPDFHeader
        }
        
        // Check for PDF magic number
        let pdfHeader = String(data: headerData.prefix(4), encoding: .ascii)
        guard pdfHeader == "%PDF" else {
            throw WebUploadValidationError.invalidPDFHeader
        }
    }
}

// MARK: - Validation Error Types

enum WebUploadValidationError: Error {
    case emptyFilename
    case filenameTooLong(Int, Int)
    case invalidFilenameCharacters
    case unsupportedFileType(String)
    case emptyFile
    case fileTooLarge(Int64, Int64)
    case fileNotFound
    case cannotReadFileAttributes
    case cannotReadFile
    case sizeMismatch(actual: Int64, expected: Int64)
    case invalidPDFHeader
    case invalidQRCodeFormat
    case invalidQRCodeScheme(String)
    case invalidQRCodeHost(String)
    case missingQRCodeParameters
    case missingRequiredParameters
    case invalidIDFormat(String)
    case timestampTooOld(Date)
    case timestampInFuture(Date)
    
    var localizedDescription: String {
        switch self {
        case .emptyFilename:
            return "Filename cannot be empty"
        case .filenameTooLong(let actual, let max):
            return "Filename too long: \(actual) characters (max: \(max))"
        case .invalidFilenameCharacters:
            return "Filename contains invalid characters"
        case .unsupportedFileType(let ext):
            return "Unsupported file type: \(ext)"
        case .emptyFile:
            return "File is empty"
        case .fileTooLarge(let actual, let max):
            return "File too large: \(actual) bytes (max: \(max))"
        case .fileNotFound:
            return "File not found"
        case .cannotReadFileAttributes:
            return "Cannot read file attributes"
        case .cannotReadFile:
            return "Cannot read file"
        case .sizeMismatch(let actual, let expected):
            return "File size mismatch: got \(actual), expected \(expected)"
        case .invalidPDFHeader:
            return "Invalid PDF file header"
        case .invalidQRCodeFormat:
            return "Invalid QR code format"
        case .invalidQRCodeScheme(let scheme):
            return "Invalid QR code scheme: \(scheme)"
        case .invalidQRCodeHost(let host):
            return "Invalid QR code host: \(host)"
        case .missingQRCodeParameters:
            return "Missing QR code parameters"
        case .missingRequiredParameters:
            return "Missing required parameters"
        case .invalidIDFormat(let id):
            return "Invalid ID format: \(id)"
        case .timestampTooOld(let date):
            return "Timestamp too old: \(date)"
        case .timestampInFuture(let date):
            return "Timestamp in future: \(date)"
        }
    }
} 