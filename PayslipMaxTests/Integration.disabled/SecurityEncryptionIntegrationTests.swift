import XCTest
import SwiftData
import CryptoKit
@testable import PayslipMax

@MainActor
class SecurityEncryptionIntegrationTests: XCTestCase {
    
    var securityService: SecurityServiceImpl!
    var modelContext: ModelContext!
    var dataService: DataServiceImpl!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Setup in-memory SwiftData
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PayslipItem.self, configurations: config)
        modelContext = ModelContext(container)
        
        // Setup security service
        securityService = SecurityServiceImpl()
        
        // Setup data service with real security service
        let mockPayslipRepository = MockPayslipRepository(modelContext: modelContext)
        dataService = DataServiceImpl(
            securityService: securityService,
            modelContext: modelContext,
            payslipRepository: mockPayslipRepository
        )
    }
    
    override func tearDownWithError() throws {
        securityService = nil
        modelContext = nil
        dataService = nil
        
        // Clean up UserDefaults
        UserDefaults.standard.removeObject(forKey: "app_pin")
        try super.tearDownWithError()
    }
    
    // MARK: - End-to-End Security Integration Tests
    
    func testEndToEndSecurityWorkflow_InitializePINEncryptDecrypt() async throws {
        // Given - Initialize security service
        try await securityService.initialize()
        XCTAssertTrue(securityService.isInitialized)
        
        // When - Setup PIN
        let testPin = "1234"
        try await securityService.setupPIN(pin: testPin)
        
        // Then - Verify PIN
        let isValidPin = try await securityService.verifyPIN(pin: testPin)
        XCTAssertTrue(isValidPin)
        
        // When - Encrypt sensitive data
        let sensitiveData = Data("Sensitive payslip information: John Doe, Salary: $75,000".utf8)
        let encryptedData = try await securityService.encryptData(sensitiveData)
        
        // Then - Verify encryption worked
        XCTAssertNotEqual(encryptedData, sensitiveData)
        XCTAssertGreaterThan(encryptedData.count, 0)
        
        // When - Decrypt data
        let decryptedData = try await securityService.decryptData(encryptedData)
        
        // Then - Verify decryption worked
        XCTAssertEqual(decryptedData, sensitiveData)
        
        // When - Verify incorrect PIN fails
        let isInvalidPin = try await securityService.verifyPIN(pin: "9999")
        
        // Then
        XCTAssertFalse(isInvalidPin)
    }
    
    func testSecurityAndDataServiceIntegration_InitializeAndSaveEncryptedPayslip() async throws {
        // Given - Initialize services
        try await dataService.initialize()
        XCTAssertTrue(dataService.isInitialized)
        
        // Create a payslip with sensitive data
        let payslip = PayslipItem(
            id: UUID(),
            name: "Sensitive Payslip - John Doe",
            data: Data("Confidential salary data".utf8)
        )
        
        // When - Save payslip (should be encrypted by the security service)
        try await dataService.save(payslip)
        
        // Then - Fetch payslips and verify data integrity
        let fetchedPayslips: [PayslipItem] = try await dataService.fetch(PayslipItem.self)
        XCTAssertEqual(fetchedPayslips.count, 1)
        
        let fetchedPayslip = fetchedPayslips.first!
        XCTAssertEqual(fetchedPayslip.id, payslip.id)
        XCTAssertEqual(fetchedPayslip.name, payslip.name)
        XCTAssertEqual(fetchedPayslip.data, payslip.data)
    }
    
    func testMultipleEncryptionDecryptionOperations_MaintainDataIntegrity() async throws {
        // Given - Initialize security service
        try await securityService.initialize()
        
        // Create multiple test data samples
        let testDataSamples = [
            Data("Payslip 1: John Doe - $50,000".utf8),
            Data("Payslip 2: Jane Smith - $60,000".utf8),
            Data("Payslip 3: Bob Johnson - $55,000".utf8),
            Data("Special characters: äöü 中文 🔒".utf8),
            Data() // Empty data
        ]
        
        var encryptedSamples: [Data] = []
        
        // When - Encrypt all samples
        for originalData in testDataSamples {
            let encryptedData = try await securityService.encryptData(originalData)
            encryptedSamples.append(encryptedData)
            
            // Verify each encryption produces different output even for same input
            if !originalData.isEmpty {
                let secondEncryption = try await securityService.encryptData(originalData)
                XCTAssertNotEqual(encryptedData, secondEncryption, "Same data should produce different ciphertext")
            }
        }
        
        // Then - Decrypt all samples and verify integrity
        for (index, encryptedData) in encryptedSamples.enumerated() {
            let decryptedData = try await securityService.decryptData(encryptedData)
            XCTAssertEqual(decryptedData, testDataSamples[index], "Decrypted data should match original")
        }
    }
    
    func testConcurrentEncryptionOperations_ThreadSafety() async throws {
        // Given - Initialize security service
        try await securityService.initialize()
        
        let testData = Data("Concurrent test data".utf8)
        let operationCount = 10
        
        // When - Perform concurrent encryption operations
        await withTaskGroup(of: (Data, Data).self) { group in
            for _ in 0..<operationCount {
                group.addTask {
                    let encrypted = try! await self.securityService.encryptData(testData)
                    let decrypted = try! await self.securityService.decryptData(encrypted)
                    return (encrypted, decrypted)
                }
            }
            
            // Then - Verify all operations completed successfully
            var results: [(Data, Data)] = []
            for await result in group {
                results.append(result)
            }
            
            XCTAssertEqual(results.count, operationCount)
            
            // Verify all decrypted data matches original
            for (_, decrypted) in results {
                XCTAssertEqual(decrypted, testData)
            }
            
            // Verify all encrypted data is different (due to random nonces)
            let encryptedDataSet = Set(results.map { $0.0 })
            XCTAssertEqual(encryptedDataSet.count, operationCount, "All encrypted data should be unique")
        }
    }
    
    func testSecurityServiceReinitializationFlow() async throws {
        // Given - First initialization
        try await securityService.initialize()
        let originalPin = "1234"
        try await securityService.setupPIN(pin: originalPin)
        
        let testData = Data("Test data for reinitialization".utf8)
        let firstEncryption = try await securityService.encryptData(testData)
        
        // When - Reinitialize (simulates app restart)
        try await securityService.initialize()
        
        // Then - PIN should still be accessible
        let pinStillValid = try await securityService.verifyPIN(pin: originalPin)
        XCTAssertTrue(pinStillValid, "PIN should persist across reinitializations")
        
        // But encryption key will be different (new key generated)
        let secondEncryption = try await securityService.encryptData(testData)
        XCTAssertNotEqual(firstEncryption, secondEncryption)
        
        // Previous encrypted data should no longer be decryptable with new key
        do {
            _ = try await securityService.decryptData(firstEncryption)
            XCTFail("Should not be able to decrypt with new key")
        } catch {
            // Expected - old encrypted data should fail with new key
        }
        
        // But new encryption should work
        let decrypted = try await securityService.decryptData(secondEncryption)
        XCTAssertEqual(decrypted, testData)
    }
    
    func testErrorHandlingInSecurityWorkflow() async throws {
        // Test uninitialized operations
        do {
            try await securityService.setupPIN(pin: "1234")
            XCTFail("Should throw notInitialized error")
        } catch SecurityServiceImpl.SecurityError.notInitialized {
            // Expected
        }
        
        do {
            _ = try await securityService.verifyPIN(pin: "1234")
            XCTFail("Should throw notInitialized error")
        } catch SecurityServiceImpl.SecurityError.notInitialized {
            // Expected
        }
        
        do {
            _ = try await securityService.encryptData(Data("test".utf8))
            XCTFail("Should throw notInitialized error")
        } catch SecurityServiceImpl.SecurityError.notInitialized {
            // Expected
        }
        
        // Initialize and test PIN not set error
        try await securityService.initialize()
        
        do {
            _ = try await securityService.verifyPIN(pin: "1234")
            XCTFail("Should throw pinNotSet error")
        } catch SecurityServiceImpl.SecurityError.pinNotSet {
            // Expected
        }
        
        // Set PIN and test decryption with invalid data
        try await securityService.setupPIN(pin: "1234")
        
        do {
            _ = try await securityService.decryptData(Data("invalid encrypted data".utf8))
            XCTFail("Should throw decryption error")
        } catch {
            // Expected - invalid encrypted data should fail
        }
    }
    
    func testLargeDataEncryptionPerformance() async throws {
        // Given - Initialize security service
        try await securityService.initialize()
        
        // Create large test data (1MB)
        let largeData = Data(repeating: 0xAB, count: 1_024 * 1_024)
        
        // When - Measure encryption performance
        let encryptionStartTime = CFAbsoluteTimeGetCurrent()
        let encryptedData = try await securityService.encryptData(largeData)
        let encryptionTime = CFAbsoluteTimeGetCurrent() - encryptionStartTime
        
        // When - Measure decryption performance
        let decryptionStartTime = CFAbsoluteTimeGetCurrent()
        let decryptedData = try await securityService.decryptData(encryptedData)
        let decryptionTime = CFAbsoluteTimeGetCurrent() - decryptionStartTime
        
        // Then - Verify correctness
        XCTAssertEqual(decryptedData, largeData)
        
        // Performance assertions (adjust thresholds as needed)
        XCTAssertLessThan(encryptionTime, 1.0, "Encryption should complete within 1 second")
        XCTAssertLessThan(decryptionTime, 1.0, "Decryption should complete within 1 second")
        
        print("Large data encryption time: \(encryptionTime)s")
        print("Large data decryption time: \(decryptionTime)s")
        print("Original size: \(largeData.count) bytes")
        print("Encrypted size: \(encryptedData.count) bytes")
    }
    
    func testPINSecurityProperties() async throws {
        // Given - Initialize security service
        try await securityService.initialize()
        
        let testPins = [
            "0000", // Weak PIN
            "1234", // Common PIN
            "abcd", // Alpha PIN
            "!@#$", // Special characters
            "12345678", // Long PIN
            "", // Empty PIN
            "中文密码" // Unicode PIN
        ]
        
        // When/Then - Test various PIN formats
        for pin in testPins {
            try await securityService.setupPIN(pin: pin)
            
            // Verify correct PIN works
            let isValid = try await securityService.verifyPIN(pin: pin)
            XCTAssertTrue(isValid, "PIN '\(pin)' should be valid")
            
            // Verify incorrect PIN fails
            let isInvalid = try await securityService.verifyPIN(pin: pin + "wrong")
            XCTAssertFalse(isInvalid, "Modified PIN should be invalid")
            
            // Verify case sensitivity (for alpha PINs)
            if pin.rangeOfCharacter(from: CharacterSet.letters) != nil {
                let uppercasePin = pin.uppercased()
                if uppercasePin != pin {
                    let isCaseSensitive = try await securityService.verifyPIN(pin: uppercasePin)
                    XCTAssertFalse(isCaseSensitive, "PIN should be case sensitive")
                }
            }
        }
    }
    
    func testDataServiceErrorPropagation() async throws {
        // Given - Uninitialized data service
        XCTAssertFalse(dataService.isInitialized)
        
        // When - Try to save without initialization
        let payslip = PayslipItem(id: UUID(), name: "Test", data: Data())
        
        do {
            try await dataService.save(payslip)
            // Should still work because save() initializes if needed
        } catch {
            XCTFail("Save should initialize automatically: \(error)")
        }
        
        // Verify it's now initialized
        XCTAssertTrue(dataService.isInitialized)
    }
}