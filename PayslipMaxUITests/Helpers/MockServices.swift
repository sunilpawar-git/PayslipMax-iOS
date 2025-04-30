import Foundation
import PDFKit

// MARK: - Service Protocols

/// Base protocol for all services
protocol ServiceProtocol {
    var isInitialized: Bool { get }
    func initialize() async throws
}

/// Protocol for security-related services
protocol SecurityServiceProtocol: ServiceProtocol {
    var isBiometricAuthAvailable: Bool { get }
    
    func encrypt(_ data: String) throws -> String
    func decrypt(_ data: String) throws -> String
    func authenticate() -> Bool
    func logout()
    func authenticateWithBiometrics() async throws -> Bool
    func setupPIN(pin: String) async throws
    func verifyPIN(pin: String) async throws -> Bool
    func encryptData(_ data: Data) async throws -> Data
    func decryptData(_ data: Data) async throws -> Data
}

/// Protocol for data storage services
protocol DataServiceProtocol: ServiceProtocol {
    func fetchAllPayslips() throws -> [any PayslipItemProtocol]
    func fetchPayslip(with id: UUID) throws -> (any PayslipItemProtocol)?
    func save(_ payslip: any PayslipItemProtocol) throws
    func delete(_ payslip: any PayslipItemProtocol) throws
    func deleteAll() throws
    
    func fetch<T>(_ type: T.Type) async throws -> [T] where T: Identifiable
    func save<T>(_ entity: T) async throws where T: Identifiable
    func delete<T>(_ entity: T) async throws where T: Identifiable
    func clearAllData() async throws
}

/// Protocol for PDF processing services
protocol PDFServiceProtocol: ServiceProtocol {
    func processPDF(data: Data) async throws -> (any PayslipItemProtocol)?
    func processPDF(url: URL) async throws -> (any PayslipItemProtocol)?
    func unlockPDF(data: Data, password: String) async throws -> Data
}

/// Protocol for PDF extraction services
protocol PDFExtractorProtocol {
    func extractPayslipData(from pdfDocument: PDFDocument) -> (any PayslipItemProtocol)?
    func extractPayslipData(from text: String) -> (any PayslipItemProtocol)?
    func extractText(from pdfDocument: PDFDocument) -> String
    func getAvailableParsers() -> [String]
}

// MARK: - Mock Security Service
class MockSecurityService: SecurityServiceProtocol {
    var isAuthenticated = false
    var encryptionError: Error?
    var decryptionError: Error?
    var isValidBiometricAuth = true
    var isInitialized: Bool = true
    var isBiometricAuthAvailable: Bool = true
    
    func reset() {
        isAuthenticated = false
        encryptionError = nil
        decryptionError = nil
        isValidBiometricAuth = true
    }
    
    func initialize() async throws {
        // No-op implementation for testing
    }
    
    func encrypt(_ data: String) throws -> String {
        if let error = encryptionError {
            throw error
        }
        return "ENCRYPTED_\(data)"
    }
    
    func decrypt(_ data: String) throws -> String {
        if let error = decryptionError {
            throw error
        }
        return data.replacingOccurrences(of: "ENCRYPTED_", with: "")
    }
    
    func authenticate() -> Bool {
        isAuthenticated = true
        return isAuthenticated
    }
    
    func logout() {
        isAuthenticated = false
    }
    
    func authenticateWithBiometrics() async throws -> Bool {
        if isValidBiometricAuth {
            isAuthenticated = true
            return true
        } else {
            throw NSError(domain: "com.payslipmax.auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Biometric authentication failed"])
        }
    }
    
    func setupPIN(pin: String) async throws {
        // No-op implementation for testing
    }
    
    func verifyPIN(pin: String) async throws -> Bool {
        return true // Always return true for testing
    }
    
    func encryptData(_ data: Data) async throws -> Data {
        if let error = encryptionError {
            throw error
        }
        return data // Mock implementation for testing
    }
    
    func decryptData(_ data: Data) async throws -> Data {
        if let error = decryptionError {
            throw error
        }
        return data // Mock implementation for testing
    }
}

// MARK: - Mock Data Service
class MockDataService: DataServiceProtocol {
    var payslips: [any PayslipItemProtocol] = []
    var fetchError: Error?
    var saveError: Error?
    var deleteError: Error?
    var isInitialized: Bool = true
    
    func reset() {
        payslips = []
        fetchError = nil
        saveError = nil
        deleteError = nil
    }
    
    func initialize() async throws {
        // No-op implementation for testing
    }
    
    func fetchAllPayslips() throws -> [any PayslipItemProtocol] {
        if let error = fetchError {
            throw error
        }
        return payslips
    }
    
    func fetchPayslip(with id: UUID) throws -> (any PayslipItemProtocol)? {
        if let error = fetchError {
            throw error
        }
        return payslips.first { $0.id == id }
    }
    
    func save(_ payslip: any PayslipItemProtocol) throws {
        if let error = saveError {
            throw error
        }
        
        if let index = payslips.firstIndex(where: { $0.id == payslip.id }) {
            payslips[index] = payslip
        } else {
            payslips.append(payslip)
        }
    }
    
    func delete(_ payslip: any PayslipItemProtocol) throws {
        if let error = deleteError {
            throw error
        }
        payslips.removeAll { $0.id == payslip.id }
    }
    
    func deleteAll() throws {
        if let error = deleteError {
            throw error
        }
        payslips = []
    }
    
    // Generic versions required by ServiceProtocol
    func fetch<T>(_ type: T.Type) async throws -> [T] where T: Identifiable {
        if let error = fetchError {
            throw error
        }
        
        if type is PayslipItemProtocol.Type {
            return payslips as! [T] // Cast required, but should be safe
        }
        
        return [] // Return empty array for other types
    }
    
    func fetchRefreshed<T>(_ type: T.Type) async throws -> [T] where T: Identifiable {
        // Same implementation as fetch for the mock
        if let error = fetchError {
            throw error
        }
        
        if type is PayslipItemProtocol.Type {
            return payslips as! [T]
        }
        
        return []
    }
    
    func save<T>(_ entity: T) async throws where T: Identifiable {
        if let error = saveError {
            throw error
        }
        if let payslip = entity as? any PayslipItemProtocol {
            if let index = payslips.firstIndex(where: { $0.id == payslip.id }) {
                payslips[index] = payslip
            } else {
                payslips.append(payslip)
            }
        }
    }
    
    func delete<T>(_ entity: T) async throws where T: Identifiable {
        if let error = deleteError {
            throw error
        }
        if let payslip = entity as? any PayslipItemProtocol {
            payslips.removeAll { $0.id == payslip.id }
        }
    }
    
    func clearAllData() async throws {
        if let error = deleteError {
            throw error
        }
        payslips = []
    }
}

// MARK: - Mock PDF Service
class MockPDFService: PDFServiceProtocol {
    var pdfData: Data?
    var pdfText: String = """
    SALARY SLIP
    Name: Test User
    Account Number: 1234567890
    PAN: ABCDE1234F
    Month: January
    Year: 2025
    
    EARNINGS:
    Basic Pay: 3000.00
    DA: 1500.00
    MSP: 500.00
    Total: 5000.00
    
    DEDUCTIONS:
    DSOP: 500.00
    ITAX: 800.00
    AGIF: 200.00
    Total: 1500.00
    
    NET AMOUNT: 3500.00
    """
    
    var processPDFError: Error?
    var unlockPDFError: Error?
    var isInitialized: Bool = true
    
    func reset() {
        processPDFError = nil
        unlockPDFError = nil
    }
    
    func initialize() async throws {
        // No-op implementation for testing
    }
    
    func processPDF(data: Data) async throws -> (any PayslipItemProtocol)? {
        if let error = processPDFError {
            throw error
        }
        
        return TestPayslipItem.sample()
    }
    
    func processPDF(url: URL) async throws -> (any PayslipItemProtocol)? {
        if let error = processPDFError {
            throw error
        }
        
        return TestPayslipItem.sample()
    }
    
    func unlockPDF(data: Data, password: String) async throws -> Data {
        if let error = unlockPDFError {
            throw error
        }
        
        return data
    }
}

// MARK: - Mock PDF Extractor
class MockPDFExtractor: PDFExtractorProtocol {
    var extractionError: Error?
    var extractTextResult: String = """
    SALARY SLIP
    Name: Test User
    Account Number: 1234567890
    PAN: ABCDE1234F
    Month: January
    Year: 2025
    
    EARNINGS:
    Basic Pay: 3000.00
    DA: 1500.00
    MSP: 500.00
    Total: 5000.00
    
    DEDUCTIONS:
    DSOP: 500.00
    ITAX: 800.00
    AGIF: 200.00
    Total: 1500.00
    
    NET AMOUNT: 3500.00
    """
    
    var availableParsers = ["PCDA Parser", "Generic Parser", "Custom Parser"]
    var reset: () -> Void = {}
    
    func extractPayslipData(from pdfDocument: PDFDocument) -> (any PayslipItemProtocol)? {
        if extractionError != nil {
            return nil
        }
        
        return TestPayslipItem.sample()
    }
    
    func extractPayslipData(from text: String) -> (any PayslipItemProtocol)? {
        if extractionError != nil {
            return nil
        }
        
        return TestPayslipItem.sample()
    }
    
    func extractText(from pdfDocument: PDFDocument) -> String {
        return extractTextResult
    }
    
    func getAvailableParsers() -> [String] {
        return availableParsers
    }
} 