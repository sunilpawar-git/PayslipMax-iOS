import Foundation

/// A protocol that defines the basic requirements for a service.
@MainActor protocol ServiceProtocol {
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
    
    /// Authenticates the user using biometrics
    func authenticateWithBiometrics() async throws -> Bool
    
    /// Sets up a PIN for the application
    func setupPIN(pin: String) async throws
    
    /// Verifies a PIN against the stored PIN
    func verifyPIN(pin: String) async throws -> Bool
    
    /// Encrypts data using the system's security services
    func encryptData(_ data: Data) async throws -> Data
    
    /// Decrypts data using the system's security services
    func decryptData(_ data: Data) async throws -> Data
}

/// Protocol for data service operations
@MainActor protocol DataServiceProtocol: ServiceProtocol {
    /// Fetches entities of the specified type
    func fetch<T>(_ type: T.Type) async throws -> [T] where T: Identifiable
    
    /// Saves an entity
    func save<T>(_ entity: T) async throws where T: Identifiable
    
    /// Deletes an entity
    func delete<T>(_ entity: T) async throws where T: Identifiable
    
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