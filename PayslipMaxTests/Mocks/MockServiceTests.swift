import XCTest
@testable import PayslipMax

/// Tests for mock services used in the application
@MainActor
final class MockServiceTests: XCTestCase {
    
    // MARK: - Security Service Tests
    
    func testMockSecurityService() {
        let mockSecurity = MockSecurityService()
        
        // Test initialization
        XCTAssertNotNil(mockSecurity, "Mock security service should initialize properly")
        
        // Test authentication
        var authResult: Bool?
        let expectation1 = expectation(description: "Authentication")
        
        Task {
            authResult = await mockSecurity.authenticate(withBiometrics: true)
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 1.0)
        XCTAssertEqual(authResult, true, "Authentication should succeed with biometrics enabled")
        
        // Test encryption/decryption
        let testData = "Test string to encrypt".data(using: .utf8)!
        
        var encryptedData: Data?
        var decryptedData: Data?
        let expectation2 = expectation(description: "Encryption")
        
        Task {
            encryptedData = await mockSecurity.encrypt(data: testData)
            expectation2.fulfill()
        }
        
        wait(for: [expectation2], timeout: 1.0)
        XCTAssertNotNil(encryptedData, "Encrypted data should not be nil")
        XCTAssertNotEqual(encryptedData, testData, "Encrypted data should be different from original")
        
        if let encryptedData = encryptedData {
            let expectation3 = expectation(description: "Decryption")
            
            Task {
                decryptedData = await mockSecurity.decrypt(data: encryptedData)
                expectation3.fulfill()
            }
            
            wait(for: [expectation3], timeout: 1.0)
            XCTAssertNotNil(decryptedData, "Decrypted data should not be nil")
            XCTAssertEqual(decryptedData, testData, "Decrypted data should match original")
        }
    }
    
    // MARK: - Data Service Tests
    
    func testMockDataService() {
        let mockData = MockDataService()
        
        // Test initialization
        XCTAssertNotNil(mockData, "Mock data service should initialize properly")
        
        // Test saving data
        let testItem = TestDataGenerator.samplePayslipItem()
        
        var saveResult: Bool?
        let expectation1 = expectation(description: "Save data")
        
        Task {
            saveResult = await mockData.savePayslip(testItem)
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 1.0)
        XCTAssertEqual(saveResult, true, "Saving a payslip should succeed")
        
        // Test fetching data
        var fetchedItems: [PayslipItem]?
        let expectation2 = expectation(description: "Fetch data")
        
        Task {
            fetchedItems = await mockData.fetchPayslips()
            expectation2.fulfill()
        }
        
        wait(for: [expectation2], timeout: 1.0)
        XCTAssertNotNil(fetchedItems, "Fetched items should not be nil")
        XCTAssertGreaterThanOrEqual(fetchedItems?.count ?? 0, 1, "At least one payslip should be fetched")
        XCTAssertEqual(fetchedItems?.first?.id, testItem.id, "Fetched item should match saved item")
    }
} 