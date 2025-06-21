import Foundation
import CommonCrypto

/// Protocol defining QR code generation functionality for web uploads
protocol QRCodeGenerationServiceProtocol {
    func generateQRCode(for uploadInfo: WebUploadInfo) -> String
    func parseQRCode(_ qrCodeString: String) throws -> WebUploadInfo
    func validateQRCodeFormat(_ qrCodeString: String) -> Bool
}

/// Service responsible for QR code generation and parsing for web uploads
class QRCodeGenerationService: QRCodeGenerationServiceProtocol {
    // MARK: - Constants
    private static let qrCodeScheme = "payslipmax"
    private static let qrCodeHost = "upload"
    
    // MARK: - Dependencies
    private let validationService: WebUploadValidationServiceProtocol
    
    // MARK: - Initialization
    init(validationService: WebUploadValidationServiceProtocol) {
        self.validationService = validationService
    }
    
    // MARK: - Public Methods
    
    func generateQRCode(for uploadInfo: WebUploadInfo) -> String {
        // Create URL components
        var components = URLComponents()
        components.scheme = Self.qrCodeScheme
        components.host = Self.qrCodeHost
        
        // Build query items
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "id", value: uploadInfo.stringID ?? uploadInfo.id.uuidString),
            URLQueryItem(name: "filename", value: uploadInfo.filename)
        ]
        
        // Add optional parameters
        if uploadInfo.fileSize > 0 {
            queryItems.append(URLQueryItem(name: "size", value: String(uploadInfo.fileSize)))
        }
        
        // Add timestamp
        let timestamp = uploadInfo.uploadedAt.timeIntervalSince1970
        queryItems.append(URLQueryItem(name: "timestamp", value: String(Int(timestamp))))
        
        // Add password protection flag
        if uploadInfo.isPasswordProtected {
            queryItems.append(URLQueryItem(name: "password", value: "true"))
        }
        
        // Add secure token/hash if available
        if let secureToken = uploadInfo.secureToken {
            queryItems.append(URLQueryItem(name: "hash", value: secureToken))
        }
        
        components.queryItems = queryItems
        
        // Generate the QR code string
        let qrCodeString = components.url?.absoluteString ?? ""
        
        print("QRCodeGenerationService: Generated QR code for: \(uploadInfo.filename)")
        print("QRCodeGenerationService: QR code string: \(qrCodeString)")
        
        return qrCodeString
    }
    
    func parseQRCode(_ qrCodeString: String) throws -> WebUploadInfo {
        print("QRCodeGenerationService: Parsing QR code: \(qrCodeString)")
        
        // Use the validation service to parse and validate
        let uploadInfo = try validationService.validateQRCodeData(qrCodeString)
        
        print("QRCodeGenerationService: Successfully parsed QR code for: \(uploadInfo.filename)")
        return uploadInfo
    }
    
    func validateQRCodeFormat(_ qrCodeString: String) -> Bool {
        do {
            _ = try parseQRCode(qrCodeString)
            return true
        } catch {
            print("QRCodeGenerationService: QR code validation failed: \(error)")
            return false
        }
    }
    
    // MARK: - Helper Methods
    
    /// Generate a secure hash for the upload (could be used as token)
    func generateSecureHash(for uploadInfo: WebUploadInfo) -> String {
        let dataToHash = "\(uploadInfo.id.uuidString)_\(uploadInfo.filename)_\(uploadInfo.uploadedAt.timeIntervalSince1970)"
        return dataToHash.sha256Hash
    }
    
    /// Create a deep link URL from upload info
    func createDeepLinkURL(for uploadInfo: WebUploadInfo) -> URL? {
        let qrCodeString = generateQRCode(for: uploadInfo)
        return URL(string: qrCodeString)
    }
    
    /// Extract just the query parameters from a QR code
    func extractParameters(from qrCodeString: String) -> [String: String]? {
        guard let url = URL(string: qrCodeString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return nil
        }
        
        return Dictionary(uniqueKeysWithValues: queryItems.compactMap { item in
            item.value != nil ? (item.name, item.value!) : nil
        })
    }
    
    /// Validate QR code scheme and host only (basic format check)
    func isValidQRCodeFormat(_ qrCodeString: String) -> Bool {
        guard let url = URL(string: qrCodeString) else { return false }
        
        return url.scheme == Self.qrCodeScheme && url.host == Self.qrCodeHost
    }
    
    /// Get QR code statistics for monitoring
    func getQRCodeStatistics(for qrCodeString: String) -> QRCodeStatistics? {
        guard let parameters = extractParameters(from: qrCodeString) else {
            return nil
        }
        
        let hasSecureToken = parameters["hash"] != nil
        let isPasswordProtected = parameters["password"] == "true"
        let hasFileSize = parameters["size"] != nil
        let hasTimestamp = parameters["timestamp"] != nil
        
        return QRCodeStatistics(
            parameterCount: parameters.count,
            hasSecureToken: hasSecureToken,
            isPasswordProtected: isPasswordProtected,
            hasFileSize: hasFileSize,
            hasTimestamp: hasTimestamp,
            qrCodeLength: qrCodeString.count
        )
    }
}

// MARK: - Supporting Types

struct QRCodeStatistics {
    let parameterCount: Int
    let hasSecureToken: Bool
    let isPasswordProtected: Bool
    let hasFileSize: Bool
    let hasTimestamp: Bool
    let qrCodeLength: Int
    
    var completenessScore: Double {
        var score = 0.0
        score += hasSecureToken ? 0.3 : 0.0
        score += isPasswordProtected ? 0.2 : 0.0
        score += hasFileSize ? 0.2 : 0.0
        score += hasTimestamp ? 0.2 : 0.0
        score += parameterCount >= 4 ? 0.1 : 0.0
        return score
    }
}

// MARK: - QR Code Error Types

enum WebUploadQRCodeError: Error {
    case invalidFormat
    case missingRequiredParameters
    case invalidScheme
    case invalidHost
    case parsingFailed
    
    var localizedDescription: String {
        switch self {
        case .invalidFormat:
            return "Invalid QR code format"
        case .missingRequiredParameters:
            return "Missing required parameters in QR code"
        case .invalidScheme:
            return "Invalid QR code scheme"
        case .invalidHost:
            return "Invalid QR code host"
        case .parsingFailed:
            return "Failed to parse QR code"
        }
    }
} 