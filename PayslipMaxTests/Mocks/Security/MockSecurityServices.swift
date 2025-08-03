import Foundation
import SwiftData
import PDFKit
#if canImport(UIKit)
import UIKit
#endif
import SwiftUI
@testable import PayslipMax

// Using SecurityPolicy and SecurityViolation from main app protocol file

// MARK: - Mock Security Service
class MockSecurityService: SecurityServiceProtocol {
    var isInitialized: Bool = false
    var shouldAuthenticateSuccessfully = true
    var shouldFail = false
    var encryptionResult: Data?
    var decryptionResult: Data?
    var isBiometricAuthAvailable: Bool = true
    var isSessionValid: Bool = false
    var failedAuthenticationAttempts: Int = 0
    var isAccountLocked: Bool = false
    var securityPolicy: SecurityPolicy = SecurityPolicy()
    
    // Track method calls for verification in tests
    var initializeCallCount = 0
    var encryptCallCount = 0
    var decryptCallCount = 0
    var authenticateCount = 0
    var setupPINCallCount = 0
    var verifyPINCallCount = 0
    
    func reset() {
        isInitialized = false
        shouldAuthenticateSuccessfully = true
        shouldFail = false
        encryptionResult = nil
        decryptionResult = nil
        isBiometricAuthAvailable = true
        initializeCallCount = 0
        encryptCallCount = 0
        decryptCallCount = 0
        authenticateCount = 0
        setupPINCallCount = 0
        verifyPINCallCount = 0
    }
    
    func initialize() async throws {
        initializeCallCount += 1
        if shouldFail {
            throw MockError.initializationFailed
        }
        isInitialized = true
    }
    
    func authenticateWithBiometrics() async throws -> Bool {
        authenticateCount += 1
        if shouldFail {
            throw MockError.authenticationFailed
        }
        return shouldAuthenticateSuccessfully
    }
    
    func setupPIN(pin: String) async throws {
        setupPINCallCount += 1
        if shouldFail {
            throw MockError.setupPINFailed
        }
    }
    
    func verifyPIN(pin: String) async throws -> Bool {
        verifyPINCallCount += 1
        if shouldFail {
            throw MockError.verifyPINFailed
        }
        return pin == "1234" // Simple mock implementation
    }
    
    func encryptData(_ data: Data) async throws -> Data {
        encryptCallCount += 1
        if shouldFail {
            throw MockError.encryptionFailed
        }
        if let result = encryptionResult {
            return result
        }
        // Return a modified version of the data to simulate encryption
        var modifiedData = data
        modifiedData.append(contentsOf: [0xFF, 0xEE, 0xDD, 0xCC]) // Add some bytes
        return modifiedData
    }
    
    func decryptData(_ data: Data) async throws -> Data {
        decryptCallCount += 1
        if shouldFail {
            throw MockError.decryptionFailed
        }
        if let result = decryptionResult {
            return result
        }
        // Remove the extra bytes that were added during encryption
        if data.count >= 4 {
            return data.dropLast(4)
        }
        // Fallback if the data is too short
        return data
    }
    
    // Synchronous encryption/decryption methods for tests
    func encryptData(_ data: Data) throws -> Data {
        encryptCallCount += 1
        if shouldFail {
            throw MockError.encryptionFailed
        }
        if let result = encryptionResult {
            return result
        }
        // Return a modified version of the data to simulate encryption
        var modifiedData = data
        modifiedData.append(contentsOf: [0xFF, 0xEE, 0xDD, 0xCC]) // Add some bytes
        return modifiedData
    }
    
    func decryptData(_ data: Data) throws -> Data {
        decryptCallCount += 1
        if shouldFail {
            throw MockError.decryptionFailed
        }
        if let result = decryptionResult {
            return result
        }
        // Remove the extra bytes that were added during encryption
        if data.count >= 4 {
            return data.dropLast(4)
        }
        // Fallback if the data is too short
        return data
    }
    
    // MARK: - Additional Security Methods
    
    func authenticateWithBiometrics(reason: String) async throws {
        authenticateCount += 1
        if shouldFail {
            failedAuthenticationAttempts += 1
            if failedAuthenticationAttempts >= securityPolicy.maxFailedAttempts {
                isAccountLocked = true
            }
            throw MockError.authenticationFailed
        }
    }
    
    func startSecureSession() {
        isSessionValid = true
    }
    
    func invalidateSession() {
        isSessionValid = false
    }
    
    func storeSecureData(_ data: Data, forKey key: String) -> Bool {
        // Mock implementation always succeeds
        return !shouldFail
    }
    
    func retrieveSecureData(forKey key: String) -> Data? {
        // Mock implementation returns test data
        return shouldFail ? nil : "mock_secure_data".data(using: .utf8)
    }
    
    func deleteSecureData(forKey key: String) -> Bool {
        // Mock implementation always succeeds
        return !shouldFail
    }
    
    func handleSecurityViolation(_ violation: SecurityViolation) {
        switch violation {
        case .unauthorizedAccess, .sessionTimeout:
            invalidateSession()
        case .tooManyFailedAttempts:
            isAccountLocked = true
            invalidateSession()
        }
    }
}

// MARK: - Mock Encryption Service
class MockEncryptionService: EncryptionServiceProtocol {
    // Flags to control behavior
    var shouldFailEncryption = false
    var shouldFailDecryption = false
    
    // Track method calls
    var encryptCallCount = 0
    var decryptCallCount = 0
    var encryptCalled = false
    var decryptCalled = false
    var initializeCalled = false
    var encryptionCount = 0
    var decryptionCount = 0
    var shouldFailKeyManagement = false
    
    // Result simulation
    var encryptResult: Result<Data, Error> = .success(Data())
    var decryptResult: Result<Data, Error> = .success(Data())
    var lastDataToEncrypt: Data?
    var lastDataToDecrypt: Data?
    
    func reset() {
        shouldFailEncryption = false
        shouldFailDecryption = false
        encryptCallCount = 0
        decryptCallCount = 0
        encryptionCount = 0
        decryptionCount = 0
        shouldFailKeyManagement = false
        encryptCalled = false
        decryptCalled = false
        initializeCalled = false
    }
    
    func encrypt(_ data: Data) throws -> Data {
        encryptCallCount += 1
        encryptionCount += 1
        encryptCalled = true
        lastDataToEncrypt = data
        
        if shouldFailKeyManagement {
            throw MockError.encryptionFailed
        }
        
        switch encryptResult {
        case .success(let result):
            return result.isEmpty ? data.base64EncodedData() : result
        case .failure(let error):
            throw error
        }
    }
    
    func decrypt(_ data: Data) throws -> Data {
        decryptCallCount += 1
        decryptionCount += 1
        decryptCalled = true
        lastDataToDecrypt = data
        
        if shouldFailKeyManagement {
            throw MockError.decryptionFailed
        }
        
        switch decryptResult {
        case .success(let result):
            if result.isEmpty {
                if let decodedData = Data(base64Encoded: data) {
                    return decodedData
                } else {
                    throw EncryptionService.EncryptionError.decryptionFailed
                }
            } else {
                return result
            }
        case .failure(let error):
            throw error
        }
    }
}

// MARK: - Mock Payslip Encryption Service
/* Temporarily disabled for core test execution
class MockPayslipEncryptionService: PayslipEncryptionServiceProtocol {
    // Flags to control behavior
    var shouldFailEncryption = false
    var shouldFailDecryption = false
    
    // Track method calls
    var encryptSensitiveDataCallCount = 0
    var decryptSensitiveDataCallCount = 0
    
    // Last parameters received
    var lastPayslip: AnyPayslip?
    
    func reset() {
        shouldFailEncryption = false
        shouldFailDecryption = false
        encryptSensitiveDataCallCount = 0
        decryptSensitiveDataCallCount = 0
        lastPayslip = nil
    }
    
    func encryptSensitiveData(in payslip: inout AnyPayslip) throws -> (nameEncrypted: Bool, accountNumberEncrypted: Bool, panNumberEncrypted: Bool) {
        encryptSensitiveDataCallCount += 1
        lastPayslip = payslip
        
        if shouldFailEncryption {
            throw MockError.encryptionFailed
        }
        
        // Simulate encryption by prefixing with "ENC:"
        if !payslip.name.hasPrefix("ENC:") {
            payslip.name = "ENC:" + payslip.name
        }
        
        if !payslip.accountNumber.hasPrefix("ENC:") {
            payslip.accountNumber = "ENC:" + payslip.accountNumber
        }
        
        if !payslip.panNumber.hasPrefix("ENC:") {
            payslip.panNumber = "ENC:" + payslip.panNumber
        }
        
        return (nameEncrypted: true, accountNumberEncrypted: true, panNumberEncrypted: true)
    }
    
    func decryptSensitiveData(in payslip: inout AnyPayslip) throws -> (nameDecrypted: Bool, accountNumberDecrypted: Bool, panNumberDecrypted: Bool) {
        decryptSensitiveDataCallCount += 1
        lastPayslip = payslip
        
        if shouldFailDecryption {
            throw MockError.decryptionFailed
        }
        
        // Simulate decryption by removing the "ENC:" prefix
        var nameDecrypted = false
        var accountNumberDecrypted = false
        var panNumberDecrypted = false
        
        if payslip.name.hasPrefix("ENC:") {
            payslip.name = String(payslip.name.dropFirst(4))
            nameDecrypted = true
        }
        
        if payslip.accountNumber.hasPrefix("ENC:") {
            payslip.accountNumber = String(payslip.accountNumber.dropFirst(4))
            accountNumberDecrypted = true
        }
        
        if payslip.panNumber.hasPrefix("ENC:") {
            payslip.panNumber = String(payslip.panNumber.dropFirst(4))
            panNumberDecrypted = true
        }
        
        return (nameDecrypted: nameDecrypted, accountNumberDecrypted: accountNumberDecrypted, panNumberDecrypted: panNumberDecrypted)
    }
}

*/

// MARK: - Fallback Payslip Encryption Service  
/* Temporarily disabled for core test execution
class FallbackPayslipEncryptionService: PayslipEncryptionServiceProtocol {
    private let error: Error
    
    init(error: Error) {
        self.error = error
    }
    
    func encryptSensitiveData(in payslip: inout AnyPayslip) throws -> (nameEncrypted: Bool, accountNumberEncrypted: Bool, panNumberEncrypted: Bool) {
        // Rethrow the original error
        throw error
    }
    
    func decryptSensitiveData(in payslip: inout AnyPayslip) throws -> (nameDecrypted: Bool, accountNumberDecrypted: Bool, panNumberDecrypted: Bool) {
        // Rethrow the original error
        throw error
    }
}
*/