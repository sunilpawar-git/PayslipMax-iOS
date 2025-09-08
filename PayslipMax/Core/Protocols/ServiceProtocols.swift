import Foundation

/// Security violation types
enum SecurityViolation {
    case unauthorizedAccess
    case tooManyFailedAttempts
    case sessionTimeout
}

/// Security policy configuration
class SecurityPolicy {
    var requiresBiometricAuth: Bool = true
    var requiresDataEncryption: Bool = true
    var sessionTimeoutMinutes: Int = 30
    var maxFailedAttempts: Int = 3
}

/// A protocol that defines the basic requirements for a service.
@MainActor
public protocol ServiceProtocol {
    /// Indicates whether the service has been initialized.
    var isInitialized: Bool { get }

    /// Initializes the service.
    func initialize() async throws
}

/// Protocol for PDF service compatibility with existing code
@MainActor protocol PDFServiceProtocol: ServiceProtocol {
    /// Processes the PDF file at the specified URL.
    func process(_ url: URL) async throws -> Data

    /// Extracts information from the processed data.
    func extract(_ data: Data) -> [String: String]

    /// Unlocks a password-protected PDF document with the provided password.
    func unlockPDF(data: Data, password: String) async throws -> Data
}

/// Protocol for security service operations
@MainActor protocol SecurityServiceProtocol: ServiceProtocol {
    /// Checks if biometric authentication is available
    var isBiometricAuthAvailable: Bool { get }

    /// Session validity status
    var isSessionValid: Bool { get }

    /// Number of failed authentication attempts
    var failedAuthenticationAttempts: Int { get }

    /// Account locked status
    var isAccountLocked: Bool { get }

    /// Security policy configuration
    var securityPolicy: SecurityPolicy { get }

    /// Authenticates the user using biometrics
    func authenticateWithBiometrics() async throws -> Bool

    /// Authenticates the user using biometrics with reason
    func authenticateWithBiometrics(reason: String) async throws

    /// Sets up a PIN for the application
    func setupPIN(pin: String) async throws

    /// Verifies a PIN against the stored PIN
    func verifyPIN(pin: String) async throws -> Bool

    /// Encrypts data using the system's security services
    func encryptData(_ data: Data) async throws -> Data

    /// Decrypts data using the system's security services
    func decryptData(_ data: Data) async throws -> Data

    /// Synchronous encryption for tests
    func encryptData(_ data: Data) throws -> Data

    /// Synchronous decryption for tests
    func decryptDataSync(_ data: Data) throws -> Data

    /// Starts a secure session
    func startSecureSession()

    /// Invalidates the current session
    func invalidateSession()

    /// Stores secure data in keychain
    func storeSecureData(_ data: Data, forKey key: String) -> Bool

    /// Retrieves secure data from keychain
    func retrieveSecureData(forKey key: String) -> Data?

    /// Deletes secure data from keychain
    func deleteSecureData(forKey key: String) -> Bool

    /// Handles security violations
    func handleSecurityViolation(_ violation: SecurityViolation)
}

/// Protocol for data service operations
public protocol DataServiceProtocol: ServiceProtocol {
    /// Fetches entities of the specified type
    func fetch<T>(_ type: T.Type) async throws -> [T] where T: Identifiable

    /// Fetches entities of the specified type, ensuring a fresh fetch from the database
    func fetchRefreshed<T>(_ type: T.Type) async throws -> [T] where T: Identifiable

    /// Saves an entity
    func save<T>(_ entity: T) async throws where T: Identifiable

    /// Saves multiple entities in a batch operation
    func saveBatch<T>(_ entities: [T]) async throws where T: Identifiable

    /// Deletes an entity
    func delete<T>(_ entity: T) async throws where T: Identifiable

    /// Deletes multiple entities in a batch operation
    func deleteBatch<T>(_ entities: [T]) async throws where T: Identifiable

    /// Clears all data
    func clearAllData() async throws
}

// PDFServiceAdapter adapts the new PDFService to the old PDFServiceProtocol
@MainActor class PDFServiceAdapter: PDFServiceProtocol {
    private let newService: PDFService

    var isInitialized: Bool = true

    init(_ service: PDFService) {
        self.newService = service
    }

    func initialize() async throws {
        // Nothing to do, new service doesn't require initialization
    }

    func process(_ url: URL) async throws -> Data {
        // Just return the file data
        return try Data(contentsOf: url)
    }

    func extract(_ data: Data) -> [String: String] {
        // Use the new service's synchronous extract method
        return newService.extract(data)
    }

    func unlockPDF(data: Data, password: String) async throws -> Data {
        // Use the new service's async unlockPDF method
        return try await newService.unlockPDF(data: data, password: password)
    }
}
