import Foundation

// MARK: - Mock Encryption Service

/// A mock encryption service for testing.
class MockEncryptionService: SensitiveDataEncryptionService {
    var shouldFail = false
    var encryptCount = 0
    var decryptCount = 0
    
    func encrypt(_ data: Data) throws -> Data {
        encryptCount += 1
        if shouldFail {
            throw MockError.encryptionFailed
        }
        // For testing, we'll just return the base64 encoded data
        return data.base64EncodedData()
    }
    
    func decrypt(_ data: Data) throws -> Data {
        decryptCount += 1
        if shouldFail {
            throw MockError.decryptionFailed
        }
        // For testing, we'll assume the data is base64 encoded
        if let decodedData = Data(base64Encoded: data) {
            return decodedData
        }
        // If it's not base64 encoded, just return the original data
        return data
    }
}

/// Mock errors for testing.
enum MockError: Error {
    case encryptionFailed
    case decryptionFailed
}

// MARK: - Simple Payslip Item Factory

/// A factory for creating simple payslip items for testing.
class SimplePayslipItemFactory: PayslipItemFactoryProtocol {
    static func createEmpty() -> any PayslipItemProtocol {
        return SimplePayslipItem(
            month: "",
            year: 0,
            credits: 0,
            debits: 0,
            dsop: 0,
            tax: 0,
            name: "",
            accountNumber: "",
            panNumber: "",
            encryptionService: MockEncryptionService()
        )
    }
    
    static func createSample() -> any PayslipItemProtocol {
        return SimplePayslipItem(
            month: "January",
            year: 2025,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 500.0,
            tax: 800.0,
            name: "Test User",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F",
            encryptionService: MockEncryptionService()
        )
    }
}

// MARK: - Simple Payslip Item

/// A simple implementation of PayslipItemProtocol for testing.
class SimplePayslipItem: PayslipProtocol {
    var id: UUID
    var month: String
    var year: Int
    var credits: Double
    var debits: Double
    var dsop: Double
    var tax: Double
    var name: String
    var accountNumber: String
    var panNumber: String
    var timestamp: Date
    
    private var sensitiveDataHandler: PayslipSensitiveDataHandler
    
    init(
        id: UUID = UUID(),
        month: String,
        year: Int,
        credits: Double,
        debits: Double,
        dsop: Double,
        tax: Double,
        name: String,
        accountNumber: String,
        panNumber: String,
        timestamp: Date = Date(),
        encryptionService: SensitiveDataEncryptionService
    ) {
        self.id = id
        self.month = month
        self.year = year
        self.credits = credits
        self.debits = debits
        self.dsop = dsop
        self.tax = tax
        self.name = name
        self.accountNumber = accountNumber
        self.panNumber = panNumber
        self.timestamp = timestamp
        self.sensitiveDataHandler = PayslipSensitiveDataHandler(encryptionService: encryptionService)
    }
    
    func encryptSensitiveData() throws {
        let encrypted = try sensitiveDataHandler.encryptSensitiveFields(
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber
        )
        
        name = encrypted.name
        accountNumber = encrypted.accountNumber
        panNumber = encrypted.panNumber
    }
    
    func decryptSensitiveData() throws {
        let decrypted = try sensitiveDataHandler.decryptSensitiveFields(
            name: name,
            accountNumber: accountNumber,
            panNumber: panNumber
        )
        
        name = decrypted.name
        accountNumber = decrypted.accountNumber
        panNumber = decrypted.panNumber
    }
}

// MARK: - Tests

/// Runs tests for the PayslipItemProtocol and PayslipSensitiveDataHandler.
func runPayslipItemTests() {
    print("Running PayslipItem tests...")
    
    // Test the sensitive data handler
    testSensitiveDataHandler()
    
    // Test the simple payslip item
    testSimplePayslipItem()
    
    // Test the factory
    testPayslipItemFactory()
    
    print("All PayslipItem tests passed!")
}

/// Tests the PayslipSensitiveDataHandler.
func testSensitiveDataHandler() {
    print("Testing PayslipSensitiveDataHandler...")
    
    // Create a mock encryption service
    let mockEncryptionService = MockEncryptionService()
    
    // Create a sensitive data handler
    let handler = PayslipSensitiveDataHandler(encryptionService: mockEncryptionService)
    
    // Test encrypting a string
    do {
        let original = "Test String"
        let encrypted = try handler.encryptString(original, fieldName: "test")
        assert(encrypted != original, "Encrypted string should be different from original")
        assert(mockEncryptionService.encryptCount == 1, "Encrypt should be called once")
        
        // Test decrypting a string
        let decrypted = try handler.decryptString(encrypted, fieldName: "test")
        assert(decrypted == original, "Decrypted string should match original")
        assert(mockEncryptionService.decryptCount == 1, "Decrypt should be called once")
        
        print("✅ String encryption/decryption test passed")
    } catch {
        print("❌ String encryption/decryption test failed: \(error)")
        exit(1)
    }
    
    // Test encrypting sensitive fields
    do {
        let originalName = "John Doe"
        let originalAccountNumber = "1234567890"
        let originalPanNumber = "ABCDE1234F"
        
        let encrypted = try handler.encryptSensitiveFields(
            name: originalName,
            accountNumber: originalAccountNumber,
            panNumber: originalPanNumber
        )
        
        assert(encrypted.name != originalName, "Encrypted name should be different from original")
        assert(encrypted.accountNumber != originalAccountNumber, "Encrypted account number should be different from original")
        assert(encrypted.panNumber != originalPanNumber, "Encrypted PAN number should be different from original")
        
        // Test decrypting sensitive fields
        let decrypted = try handler.decryptSensitiveFields(
            name: encrypted.name,
            accountNumber: encrypted.accountNumber,
            panNumber: encrypted.panNumber
        )
        
        assert(decrypted.name == originalName, "Decrypted name should match original")
        assert(decrypted.accountNumber == originalAccountNumber, "Decrypted account number should match original")
        assert(decrypted.panNumber == originalPanNumber, "Decrypted PAN number should match original")
        
        print("✅ Sensitive fields encryption/decryption test passed")
    } catch {
        print("❌ Sensitive fields encryption/decryption test failed: \(error)")
        exit(1)
    }
    
    // Test encryption failure
    do {
        mockEncryptionService.shouldFail = true
        let original = "Test String"
        
        do {
            _ = try handler.encryptString(original, fieldName: "test")
            print("❌ Encryption failure test failed: Should have thrown an error")
            exit(1)
        } catch {
            assert(error is MockError, "Error should be a MockError")
            print("✅ Encryption failure test passed")
        }
    }
    
    print("All PayslipSensitiveDataHandler tests passed!")
}

/// Tests the SimplePayslipItem.
func testSimplePayslipItem() {
    print("Testing SimplePayslipItem...")
    
    // Create a mock encryption service
    let mockEncryptionService = MockEncryptionService()
    
    // Create a simple payslip item
    let payslip = SimplePayslipItem(
        month: "January",
        year: 2025,
        credits: 5000.0,
        debits: 1000.0,
        dsop: 500.0,
        tax: 800.0,
        name: "Test User",
        accountNumber: "1234567890",
        panNumber: "ABCDE1234F",
        encryptionService: mockEncryptionService
    )
    
    // Test calculation methods
    assert(payslip.calculateNetAmount() == 4000.0, "Net amount should be 4000.0")
    
    // Test property values
    assert(payslip.month == "January", "Month should be January")
    assert(payslip.year == 2025, "Year should be 2025")
    assert(payslip.credits == 5000.0, "Credits should be 5000.0")
    assert(payslip.debits == 1000.0, "Debits should be 1000.0")
    assert(payslip.dsop == 500.0, "DSOP should be 500.0")
    assert(payslip.tax == 800.0, "Tax should be 800.0")
    assert(payslip.name == "Test User", "Name should be Test User")
    assert(payslip.accountNumber == "1234567890", "Account number should be 1234567890")
    assert(payslip.panNumber == "ABCDE1234F", "PAN number should be ABCDE1234F")
    
    // Test encrypting sensitive data
    do {
        try payslip.encryptSensitiveData()
        
        assert(payslip.name != "Test User", "Name should be encrypted")
        assert(payslip.accountNumber != "1234567890", "Account number should be encrypted")
        assert(payslip.panNumber != "ABCDE1234F", "PAN number should be encrypted")
        
        // Test decrypting sensitive data
        try payslip.decryptSensitiveData()
        
        assert(payslip.name == "Test User", "Name should be decrypted")
        assert(payslip.accountNumber == "1234567890", "Account number should be decrypted")
        assert(payslip.panNumber == "ABCDE1234F", "PAN number should be decrypted")
        
        print("✅ Encryption/decryption test passed")
    } catch {
        print("❌ Encryption/decryption test failed: \(error)")
        exit(1)
    }
    
    // Test formatted description
    let description = payslip.formattedDescription()
    assert(description.contains("Test User"), "Description should contain the name")
    assert(description.contains("January"), "Description should contain the month")
    assert(description.contains("2025"), "Description should contain the year")
    assert(description.contains("5000.0"), "Description should contain the credits")
    assert(description.contains("4000.0"), "Description should contain the net amount")
    
    print("✅ Formatted description test passed")
    print("All SimplePayslipItem tests passed!")
}

/// Tests the PayslipItemFactory.
func testPayslipItemFactory() {
    print("Testing PayslipItemFactory...")
    
    // Test creating an empty payslip item
    let emptyPayslip = SimplePayslipItemFactory.createEmpty()
    assert(emptyPayslip.month == "", "Month should be empty")
    assert(emptyPayslip.credits == 0, "Credits should be 0")
    
    // Test creating a sample payslip item
    let samplePayslip = SimplePayslipItemFactory.createSample()
    assert(samplePayslip.month == "January", "Month should be January")
    assert(samplePayslip.year == 2025, "Year should be 2025")
    assert(samplePayslip.credits == 5000.0, "Credits should be 5000.0")
    
    print("✅ Factory test passed")
}

// Run the tests
runPayslipItemTests() 