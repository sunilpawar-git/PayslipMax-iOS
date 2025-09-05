import Foundation
@testable import PayslipMax

/// Central coordination for all mock services used in tests.
/// Provides centralized registry and reset functionality.
@MainActor
class MockServiceRegistry {
    
    // MARK: - Singleton
    static let shared = MockServiceRegistry()
    
    // MARK: - Mock Services
    
    /// Mock security service for authentication and encryption testing
    lazy var securityService: SecurityServiceProtocol = MockSecurityService()
    
    /// Mock PDF service for document processing testing
    lazy var pdfService: PDFServiceProtocol = MockPDFService()
    
    /// Mock PDF extractor for text extraction testing
    lazy var pdfExtractor: PDFExtractorProtocol = MockPDFExtractor()
    
    /// Mock payslip encryption service for data security testing
    lazy var payslipEncryptionService: PayslipEncryptionServiceProtocol = MockPayslipEncryptionService()
    
    /// Mock encryption service for general encryption testing
    lazy var encryptionService: EncryptionServiceProtocol = MockEncryptionService()
    
    /// Mock PDF processing service for full pipeline testing
    lazy var pdfProcessingService: PDFProcessingServiceProtocol = MockPDFProcessingService()
    
    /// Mock PDF text extraction service for text processing testing
    lazy var pdfTextExtractionService: PDFTextExtractionServiceProtocol = MockPDFTextExtractionService()
    
    /// Mock PDF parsing coordinator for coordination testing
    lazy var pdfParsingCoordinator: PDFParsingCoordinatorProtocol = MockPDFParsingCoordinator()
    
    /// Mock payslip processing pipeline for full processing testing
    lazy var payslipProcessingPipeline: PayslipProcessingPipelineProtocol = MockPayslipProcessingPipeline()
    
    /// Mock payslip validation service for validation testing
    lazy var payslipValidationService: PayslipValidationServiceProtocol = MockPayslipValidationService()
    
    /// Mock payslip format detection service for format detection testing
    lazy var payslipFormatDetectionService: PayslipFormatDetectionServiceProtocol = MockPayslipFormatDetectionService()
    
    /// Mock text extraction service for text processing testing
    lazy var textExtractionService: TextExtractionServiceProtocol = MockTextExtractionService()
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Registry Management
    
    /// Resets all mock services to their default state
    func resetAllServices() {
        // Reset all services to new instances
        securityService = MockSecurityService()
        pdfService = MockPDFService()
        pdfExtractor = MockPDFExtractor()
        payslipEncryptionService = MockPayslipEncryptionService()
        encryptionService = MockEncryptionService()
        pdfProcessingService = MockPDFProcessingService()
        pdfTextExtractionService = MockPDFTextExtractionService()
        pdfParsingCoordinator = MockPDFParsingCoordinator()
        payslipProcessingPipeline = MockPayslipProcessingPipeline()
        payslipValidationService = MockPayslipValidationService()
        payslipFormatDetectionService = MockPayslipFormatDetectionService()
        textExtractionService = MockTextExtractionService()
    }
    
    /// Configures all services for failure testing
    func configureAllForFailure() {
        // Configure each service to simulate failures
        if let mockSecurity = securityService as? MockSecurityService {
            mockSecurity.shouldFailAuth = true
        }
        
        if let mockPDF = pdfService as? MockPDFService {
            mockPDF.shouldFailProcessing = true
        }
        
        // Add more failure configurations as needed
    }
    
    /// Configures all services for success testing
    func configureAllForSuccess() {
        // Ensure all services are configured for successful operations
        if let mockSecurity = securityService as? MockSecurityService {
            mockSecurity.shouldFailAuth = false
        }
        
        if let mockPDF = pdfService as? MockPDFService {
            mockPDF.shouldFailProcessing = false
        }
        
        // Add more success configurations as needed
    }
}

// MARK: - Basic Mock Services for Tests

/// Mock security service for testing
class MockSecurityService: SecurityServiceProtocol {
    var isInitialized: Bool = true
    var shouldFailAuth = false
    var authenticateCallCount = 0
    
    // MARK: - SecurityServiceProtocol Properties
    var isBiometricAuthAvailable: Bool = true
    var isSessionValid: Bool = true
    var failedAuthenticationAttempts: Int = 0
    var isAccountLocked: Bool = false
    var securityPolicy: SecurityPolicy = SecurityPolicy()
    
    // MARK: - ServiceProtocol Methods
    func initialize() async throws {
        if shouldFailAuth { throw MockError.initializationFailed }
        isInitialized = true
    }
    
    // MARK: - Authentication Methods
    func authenticateWithBiometrics() async throws -> Bool {
        authenticateCallCount += 1
        if shouldFailAuth { throw MockError.authenticationFailed }
        return true
    }
    
    func authenticateWithBiometrics(reason: String) async throws {
        authenticateCallCount += 1
        if shouldFailAuth { throw MockError.authenticationFailed }
    }
    
    func setupPIN(pin: String) async throws {
        if shouldFailAuth { throw MockError.authenticationFailed }
    }
    
    func verifyPIN(pin: String) async throws -> Bool {
        if shouldFailAuth { throw MockError.authenticationFailed }
        return true
    }
    
    // MARK: - Encryption Methods
    func encryptData(_ data: Data) async throws -> Data {
        if shouldFailAuth { throw MockError.encryptionFailed }
        return data
    }
    
    func decryptData(_ data: Data) async throws -> Data {
        if shouldFailAuth { throw MockError.encryptionFailed }
        return data
    }
    
    func encryptData(_ data: Data) throws -> Data {
        if shouldFailAuth { throw MockError.encryptionFailed }
        return data
    }
    
    func decryptData(_ data: Data) throws -> Data {
        if shouldFailAuth { throw MockError.encryptionFailed }
        return data
    }
    
    // MARK: - Session Management
    func startSecureSession() {
        isSessionValid = true
    }
    
    func invalidateSession() {
        isSessionValid = false
    }
    
    // MARK: - Keychain Operations
    func storeSecureData(_ data: Data, forKey key: String) -> Bool {
        return !shouldFailAuth
    }
    
    func retrieveSecureData(forKey key: String) -> Data? {
        return shouldFailAuth ? nil : Data("mock secure data".utf8)
    }
    
    func deleteSecureData(forKey key: String) -> Bool {
        return !shouldFailAuth
    }
    
    // MARK: - Security Violations
    func handleSecurityViolation(_ violation: SecurityViolation) {
        switch violation {
        case .tooManyFailedAttempts:
            isAccountLocked = true
        case .sessionTimeout:
            isSessionValid = false
        case .unauthorizedAccess:
            invalidateSession()
        }
    }
}

/// Mock PDF service for testing
class MockPDFService: PDFServiceProtocol {
    var isInitialized: Bool = true
    var shouldFailProcessing = false
    
    func initialize() async throws {
        if shouldFailProcessing { throw MockError.initializationFailed }
        isInitialized = true
    }
    
    func process(_ url: URL) async throws -> Data {
        if shouldFailProcessing { throw MockError.processingFailed }
        return Data("Mock processed data".utf8)
    }
    
    func extract(_ data: Data) -> [String: String] {
        if shouldFailProcessing { return [:] }
        return ["credits": "5000", "debits": "1000", "name": "Mock Employee"]
    }
    
    func unlockPDF(data: Data, password: String) async throws -> Data {
        if shouldFailProcessing { throw MockError.processingFailed }
        return data // Return unlocked data
    }
}

/// Mock PDF extractor for testing
class MockPDFExtractor: PDFExtractorProtocol {
    var shouldFailExtraction = false
    
    func extractPayslipData(from pdfDocument: PDFDocument) async throws -> PayslipItem? {
        if shouldFailExtraction { throw MockError.extractionFailed }
        return createMockPayslip()
    }
    
    func extractPayslipData(from text: String) -> PayslipItem? {
        shouldFailExtraction ? nil : createMockPayslip()
    }
    
    func extractText(from pdfDocument: PDFDocument) async -> String {
        shouldFailExtraction ? "" : "Mock extracted text"
    }
    
    func getAvailableParsers() -> [String] { ["MockParser"] }
    
    private func createMockPayslip() -> PayslipItem {
        PayslipItem(
            id: UUID(),
            month: "January",
            year: 2024,
            organization: "Mock Org",
            employeeName: "Mock Employee",
            employeeId: "MOCK123",
            designation: "Mock Position",
            department: "Mock Department",
            payPeriod: "Mock Period",
            grossPay: 50000.0,
            netPay: 40000.0,
            totalDeductions: 10000.0,
            earnings: [:],
            deductions: [:],
            personalDetails: [:],
            additionalInfo: [:],
            pdfData: Data(),
            createdAt: Date(),
            lastModified: Date(),
            isEncrypted: false,
            encryptionKey: nil,
            payslipFormat: .corporate
        )
    }
}

// MARK: - Additional Mock Services

class MockPayslipEncryptionService: PayslipEncryptionServiceProtocol {
    func encrypt(_ payslip: PayslipItem) throws -> PayslipItem { payslip }
    func decrypt(_ payslip: PayslipItem) throws -> PayslipItem { payslip }
}

class MockEncryptionService: EncryptionServiceProtocol {
    func encrypt(_ data: Data) throws -> Data { data }
    func decrypt(_ data: Data) throws -> Data { data }
}

class MockPDFProcessingService: PDFProcessingServiceProtocol {
    func processPDF(_ data: Data) async throws -> PayslipItem {
        PayslipItem(
            id: UUID(), month: "Mock", year: 2024, organization: "Mock Org",
            employeeName: "Mock Employee", employeeId: "MOCK123", designation: "Mock Role",
            department: "Mock Dept", payPeriod: "Mock Period", grossPay: 50000, netPay: 40000,
            totalDeductions: 10000, earnings: [:], deductions: [:], personalDetails: [:],
            additionalInfo: [:], pdfData: Data(), createdAt: Date(), lastModified: Date(),
            isEncrypted: false, encryptionKey: nil, payslipFormat: .corporate
        )
    }
}

class MockPDFTextExtractionService: PDFTextExtractionServiceProtocol {
    func extractText(from document: PDFDocument) async -> String { "Mock extracted text" }
    func extractText(from data: Data) async -> String { "Mock extracted text" }
}

class MockPDFParsingCoordinator: PDFParsingCoordinatorProtocol {
    func parsePDF(_ document: PDFDocument) async throws -> PayslipItem {
        PayslipItem(
            id: UUID(), month: "Mock", year: 2024, organization: "Mock Org",
            employeeName: "Mock Employee", employeeId: "MOCK123", designation: "Mock Role",
            department: "Mock Dept", payPeriod: "Mock Period", grossPay: 50000, netPay: 40000,
            totalDeductions: 10000, earnings: [:], deductions: [:], personalDetails: [:],
            additionalInfo: [:], pdfData: Data(), createdAt: Date(), lastModified: Date(),
            isEncrypted: false, encryptionKey: nil, payslipFormat: .corporate
        )
    }
}

class MockPayslipProcessingPipeline: PayslipProcessingPipelineProtocol {
    func processPayslip(_ data: Data) async throws -> PayslipItem {
        PayslipItem(
            id: UUID(), month: "Mock", year: 2024, organization: "Mock Org",
            employeeName: "Mock Employee", employeeId: "MOCK123", designation: "Mock Role",
            department: "Mock Dept", payPeriod: "Mock Period", grossPay: 50000, netPay: 40000,
            totalDeductions: 10000, earnings: [:], deductions: [:], personalDetails: [:],
            additionalInfo: [:], pdfData: Data(), createdAt: Date(), lastModified: Date(),
            isEncrypted: false, encryptionKey: nil, payslipFormat: .corporate
        )
    }
}

class MockPayslipValidationService: PayslipValidationServiceProtocol {
    func validatePayslip(_ payslip: PayslipItem) async throws -> Bool { true }
    func validateFields(_ fields: [String: Any]) -> ValidationResult {
        ValidationResult(isValid: true, errors: [])
    }
    func getValidationRules() -> [String] { ["Rule1"] }
}

class MockPayslipFormatDetectionService: PayslipFormatDetectionServiceProtocol {
    func detectFormat(_ data: Data) async -> PayslipFormat { .corporate }
    func detectFormat(fromText text: String) -> PayslipFormat { .corporate }
    func getSupportedFormats() -> [PayslipFormat] { [.corporate, .military] }
}

class MockTextExtractionService: TextExtractionServiceProtocol {
    func extractText(from data: Data) async -> String { "Mock extracted text" }
}

// MARK: - Mock Error Types

enum MockError: Error, LocalizedError {
    case authenticationFailed
    case encryptionFailed
    case processingFailed
    case extractionFailed
    case initializationFailed
    case saveFailed
    case fetchFailed
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed: return "Mock authentication failed"
        case .encryptionFailed: return "Mock encryption failed"
        case .processingFailed: return "Mock processing failed"
        case .extractionFailed: return "Mock extraction failed"
        case .initializationFailed: return "Mock initialization failed"
        case .saveFailed: return "Mock save failed"
        case .fetchFailed: return "Mock fetch failed"
        }
    }
}

// MARK: - Supporting Types

struct ValidationResult {
    let isValid: Bool
    let errors: [ValidationError]
}

struct ValidationError: Error {
    let field: String
    let message: String
}
