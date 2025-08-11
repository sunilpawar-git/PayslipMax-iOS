import Foundation
import CryptoKit

struct ValidatedDeepLink {
    let idString: String
    let filename: String
    let size: Int
    let token: String
    let isProtected: Bool
}

protocol DeepLinkSecurityServiceProtocol {
    func validate(components: URLComponents) async throws -> ValidatedDeepLink
}

enum DeepLinkSecurityError: Error, LocalizedError {
    case missingParameters
    case expired
    case missingDeviceBinding
    case invalidSignature

    var errorDescription: String? {
        switch self {
        case .missingParameters:
            return "Missing required signed parameters"
        case .expired:
            return "Link has expired. Please generate a new link."
        case .missingDeviceBinding:
            return "Device is not registered. Please register your device first."
        case .invalidSignature:
            return "Invalid link signature."
        }
    }
}

final class DeepLinkSecurityService: DeepLinkSecurityServiceProtocol {
    private let secureStorage: SecureStorageProtocol
    private let allowedSkewSeconds: TimeInterval

    init(secureStorage: SecureStorageProtocol, allowedSkewSeconds: TimeInterval = 5 * 60) {
        self.secureStorage = secureStorage
        self.allowedSkewSeconds = allowedSkewSeconds
    }

    func validate(components: URLComponents) async throws -> ValidatedDeepLink {
        guard let items = components.queryItems else { throw DeepLinkSecurityError.missingParameters }

        func value(_ name: String) -> String? { items.first { $0.name == name }?.value }

        guard
            let idString = value("id"),
            let filename = value("filename"),
            let sizeStr = value("size"), let size = Int(sizeStr),
            let token = value("token"),
            let expStr = value("exp"), let exp = TimeInterval(expStr),
            let sigHex = value("sig")
        else {
            throw DeepLinkSecurityError.missingParameters
        }

        // Expiry check
        let now = Date().timeIntervalSince1970
        if now > exp + allowedSkewSeconds { throw DeepLinkSecurityError.expired }

        // Device binding via stored device token
        guard let deviceToken = try secureStorage.getString(key: "web_upload_device_token"), !deviceToken.isEmpty else {
            throw DeepLinkSecurityError.missingDeviceBinding
        }

        // Canonical message
        let message = "id=\(idString)&filename=\(filename)&size=\(size)&exp=\(Int(exp))&device=\(deviceToken)"

        // HMAC-SHA256 using device token as key
        let key = SymmetricKey(data: Data(deviceToken.utf8))
        let mac = HMAC<SHA256>.authenticationCode(for: Data(message.utf8), using: key)
        let macHex = mac.map { String(format: "%02x", $0) }.joined()

        guard macHex == sigHex.lowercased() else { throw DeepLinkSecurityError.invalidSignature }

        let isProtected = (value("protected").flatMap { Bool($0) }) ?? false

        return ValidatedDeepLink(idString: idString, filename: filename, size: size, token: token, isProtected: isProtected)
    }
}


