import Foundation
import SwiftData
import PDFKit
#if canImport(UIKit)
import UIKit
#endif
import SwiftUI
@testable import PayslipMax

// MARK: - Mock Security Service
class MockSecurityService: SecurityServiceProtocol {
    var isInitialized: Bool = false
    var shouldAuthenticateSuccessfully = true
    var shouldFail = false
    var encryptionResult: Data?
    var decryptionResult: Data?
    var isBiometricAuthAvailable: Bool = true
    
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
}

// MARK: - Mock Encryption Service
class MockEncryptionService: EncryptionServiceProtocol {
    // Flags to control behavior
    var shouldFailEncryption = false
    var shouldFailDecryption = false
    
    // Track method calls
    var encryptCallCount = 0
    var decryptCallCount = 0
    
    func reset() {
        shouldFailEncryption = false
        shouldFailDecryption = false
        encryptCallCount = 0
        decryptCallCount = 0
    }
    
    func encrypt(_ data: Data) throws -> Data {
        encryptCallCount += 1
        
        if shouldFailEncryption {
            throw EncryptionService.EncryptionError.encryptionFailed
        }
        
        // Simple simulation of encryption by encoding to base64
        return data.base64EncodedData()
    }
    
    func decrypt(_ data: Data) throws -> Data {
        decryptCallCount += 1
        
        if shouldFailDecryption {
            throw EncryptionService.EncryptionError.decryptionFailed
        }
        
        // Simple simulation of decryption by decoding from base64
        if let decodedData = Data(base64Encoded: data) {
            return decodedData
        } else {
            throw EncryptionService.EncryptionError.decryptionFailed
        }
    }
}

// MARK: - Mock Payslip Encryption Service
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

// MARK: - Fallback Payslip Encryption Service
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