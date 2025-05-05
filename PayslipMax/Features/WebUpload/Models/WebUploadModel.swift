import Foundation

/// Model representing information for files uploaded from the web
struct WebUploadInfo: Codable, Identifiable {
    /// Unique identifier for the upload
    let id: UUID
    /// Name of the file
    let filename: String
    /// Timestamp of when the file was uploaded
    let uploadedAt: Date
    /// Size of the file in bytes
    let fileSize: Int64
    /// Indicates if the file is password protected
    let isPasswordProtected: Bool
    /// Source of the upload (website URL)
    let source: String
    /// Status of the upload/download process
    var status: UploadStatus
    /// Temporary token for secure retrieval (if applicable)
    var secureToken: String?
    /// Local file URL if downloaded
    var localURL: URL?
    
    init(
        id: UUID = UUID(),
        filename: String,
        uploadedAt: Date = Date(),
        fileSize: Int64,
        isPasswordProtected: Bool = false,
        source: String,
        status: UploadStatus = .pending,
        secureToken: String? = nil,
        localURL: URL? = nil
    ) {
        self.id = id
        self.filename = filename
        self.uploadedAt = uploadedAt
        self.fileSize = fileSize
        self.isPasswordProtected = isPasswordProtected
        self.source = source
        self.status = status
        self.secureToken = secureToken
        self.localURL = localURL
    }
}

/// Status of an uploaded file
enum UploadStatus: String, Codable {
    /// File pending download
    case pending
    /// File is downloading
    case downloading
    /// File has been downloaded but not processed
    case downloaded
    /// File has been processed
    case processed
    /// File processing failed
    case failed
    /// File requires password
    case requiresPassword
}

/// Credentials for password-protected PDFs
struct PDFSecureCredentials: Codable {
    /// The upload ID this credential belongs to
    let uploadId: UUID
    /// The password for the PDF
    let password: String
    /// When this credential was created
    let createdAt: Date
    
    init(uploadId: UUID, password: String, createdAt: Date = Date()) {
        self.uploadId = uploadId
        self.password = password
        self.createdAt = createdAt
    }
} 