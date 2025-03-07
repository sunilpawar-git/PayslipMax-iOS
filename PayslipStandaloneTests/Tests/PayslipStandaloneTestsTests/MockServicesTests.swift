import XCTest
@testable import PayslipStandaloneTests

final class MockServicesTests: XCTestCase {
    
    // MARK: - Security Service Tests
    func testMockSecurityService_Initialize() async throws {
        // Given
        let service = MockSecurityService()
        XCTAssertFalse(service.isInitialized, "Service should not be initialized initially")
        
        // When
        try await service.initialize()
        
        // Then
        XCTAssertTrue(service.isInitialized, "Service should be initialized after initialize()")
        XCTAssertEqual(service.initializeCount, 1, "initialize() should be called once")
    }
    
    func testMockSecurityService_InitializeFails() async {
        // Given
        let service = MockSecurityService()
        service.shouldFail = true
        
        // When/Then
        do {
            try await service.initialize()
            XCTFail("initialize() should throw an error when shouldFail is true")
        } catch let error as MockError {
            XCTAssertEqual(error, MockError.initializationFailed, "Error should be initializationFailed")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
        
        XCTAssertEqual(service.initializeCount, 1, "initialize() should be called once")
    }
    
    func testMockSecurityService_Encrypt() async throws {
        // Given
        let service = MockSecurityService()
        try await service.initialize()
        let testData = "Test".data(using: .utf8)!
        
        // When
        let encryptedData = try await service.encrypt(testData)
        
        // Then
        XCTAssertEqual(encryptedData, testData, "Encrypted data should match original data in mock")
        XCTAssertEqual(service.encryptCount, 1, "encrypt() should be called once")
    }
    
    func testMockSecurityService_EncryptFails() async {
        // Given
        let service = MockSecurityService()
        try! await service.initialize()
        service.shouldFail = true
        let testData = "Test".data(using: .utf8)!
        
        // When/Then
        do {
            _ = try await service.encrypt(testData)
            XCTFail("encrypt() should throw an error when shouldFail is true")
        } catch let error as MockError {
            XCTAssertEqual(error, MockError.encryptionFailed, "Error should be encryptionFailed")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
        
        XCTAssertEqual(service.encryptCount, 1, "encrypt() should be called once")
    }
    
    func testMockSecurityService_Decrypt() async throws {
        // Given
        let service = MockSecurityService()
        try await service.initialize()
        let testData = "Test".data(using: .utf8)!
        
        // When
        let decryptedData = try await service.decrypt(testData)
        
        // Then
        XCTAssertEqual(decryptedData, testData, "Decrypted data should match original data in mock")
        XCTAssertEqual(service.decryptCount, 1, "decrypt() should be called once")
    }
    
    func testMockSecurityService_DecryptFails() async {
        // Given
        let service = MockSecurityService()
        try! await service.initialize()
        service.shouldFail = true
        let testData = "Test".data(using: .utf8)!
        
        // When/Then
        do {
            _ = try await service.decrypt(testData)
            XCTFail("decrypt() should throw an error when shouldFail is true")
        } catch let error as MockError {
            XCTAssertEqual(error, MockError.decryptionFailed, "Error should be decryptionFailed")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
        
        XCTAssertEqual(service.decryptCount, 1, "decrypt() should be called once")
    }
    
    func testMockSecurityService_Authenticate() async throws {
        // Given
        let service = MockSecurityService()
        try await service.initialize()
        service.shouldAuthenticateSuccessfully = true
        
        // When
        let result = try await service.authenticate()
        
        // Then
        XCTAssertTrue(result, "authenticate() should return true when shouldAuthenticateSuccessfully is true")
        XCTAssertEqual(service.authenticateCount, 1, "authenticate() should be called once")
    }
    
    func testMockSecurityService_AuthenticateFails() async {
        // Given
        let service = MockSecurityService()
        try! await service.initialize()
        service.shouldFail = true
        
        // When/Then
        do {
            _ = try await service.authenticate()
            XCTFail("authenticate() should throw an error when shouldFail is true")
        } catch let error as MockError {
            XCTAssertEqual(error, MockError.authenticationFailed, "Error should be authenticationFailed")
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
        
        XCTAssertEqual(service.authenticateCount, 1, "authenticate() should be called once")
    }
    
    // MARK: - Data Service Tests
    func testMockDataService_Initialize() async throws {
        // Given
        let service = MockDataService()
        XCTAssertFalse(service.isInitialized, "Service should not be initialized initially")
        
        // When
        try await service.initialize()
        
        // Then
        XCTAssertTrue(service.isInitialized, "Service should be initialized after initialize()")
        XCTAssertEqual(service.initializeCount, 1, "initialize() should be called once")
    }
    
    func testMockDataService_Save() async throws {
        // Given
        let service = MockDataService()
        try await service.initialize()
        let payslip = StandalonePayslipItem.sample()
        
        // When
        try await service.save(payslip)
        
        // Then
        XCTAssertEqual(service.saveCount, 1, "save() should be called once")
        
        // Verify the item was stored
        let payslips = try await service.fetch(StandalonePayslipItem.self)
        XCTAssertEqual(payslips.count, 1, "There should be one payslip stored")
    }
    
    func testMockDataService_Fetch() async throws {
        // Given
        let service = MockDataService()
        try await service.initialize()
        let payslip1 = StandalonePayslipItem.sample()
        let payslip2 = StandalonePayslipItem(
            month: "February",
            year: 2023,
            credits: 6000.0,
            debits: 1500.0,
            dspof: 300.0,
            tax: 900.0,
            location: "Chicago",
            name: "Jane Smith",
            accountNumber: "9876543210",
            panNumber: "ZYXWV9876G"
        )
        
        try await service.save(payslip1)
        try await service.save(payslip2)
        
        // When
        let payslips = try await service.fetch(StandalonePayslipItem.self)
        
        // Then
        XCTAssertEqual(payslips.count, 2, "There should be two payslips stored")
        XCTAssertEqual(service.fetchCount, 1, "fetch() should be called once")
    }
    
    // MARK: - PDF Service Tests
    func testMockPDFService_Initialize() async throws {
        // Given
        let service = MockPDFService()
        XCTAssertFalse(service.isInitialized, "Service should not be initialized initially")
        
        // When
        try await service.initialize()
        
        // Then
        XCTAssertTrue(service.isInitialized, "Service should be initialized after initialize()")
        XCTAssertEqual(service.initializeCount, 1, "initialize() should be called once")
    }
    
    func testMockPDFService_Process() async throws {
        // Given
        let service = MockPDFService()
        try await service.initialize()
        let testURL = URL(string: "file:///test.pdf")!
        
        // When
        let processedData = try await service.process(testURL)
        
        // Then
        XCTAssertNotNil(processedData, "Processed data should not be nil")
        XCTAssertEqual(service.processCount, 1, "process() should be called once")
    }
    
    func testMockPDFService_Extract() async throws {
        // Given
        let service = MockPDFService()
        try await service.initialize()
        let testData = Data()
        
        // When
        let payslip = try await service.extract(testData)
        
        // Then
        XCTAssertNotNil(payslip, "Extracted payslip should not be nil")
        XCTAssertEqual(service.extractCount, 1, "extract() should be called once")
        
        // Verify it's a sample payslip
        XCTAssertEqual(payslip.month, "January", "Month should be January")
        XCTAssertEqual(payslip.year, 2023, "Year should be 2023")
    }
} 