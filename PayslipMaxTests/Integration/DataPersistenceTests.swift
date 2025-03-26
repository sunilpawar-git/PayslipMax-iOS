import XCTest
import SwiftData
@testable import Payslip_Max

@MainActor
final class DataPersistenceTests: XCTestCase {
    
    // System under test
    var mockEncryptionService: MockEncryptionService!
    var mockDataService: MockDataServiceHelper!
    var testPayslip: PayslipItem!
    var testContainer: TestDIContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create mock services
        mockEncryptionService = MockEncryptionService()
        mockDataService = MockDataServiceHelper()
        
        // Set up the factory to use our mock
        _ = PayslipItem.setEncryptionServiceFactory { [unowned self] in
            return self.mockEncryptionService! as EncryptionServiceProtocolInternal
        }
        
        // Set up the test DI container
        testContainer = TestDIContainer.forTesting()
        
        // Create a test payslip
        testPayslip = PayslipItem(
            month: "January",
            year: 2023,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 500.0,
            tax: 800.0,
            name: "John Doe",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F"
        )
    }
    
    override func tearDown() async throws {
        // Reset the factory to default implementation
        PayslipItem.resetEncryptionServiceFactory()
        
        mockEncryptionService = nil
        mockDataService = nil
        testPayslip = nil
        TestDIContainer.resetToDefault()
        testContainer = nil
        try await super.tearDown()
    }
    
    // MARK: - Integration Tests
    
    func testSaveAndRetrieveEncryptedData() async throws {
        // Given - A payslip with sensitive data
        XCTAssertEqual(testPayslip.name, "John Doe")
        XCTAssertEqual(testPayslip.accountNumber, "1234567890")
        XCTAssertEqual(testPayslip.panNumber, "ABCDE1234F")
        
        // When - Encrypt sensitive data
        try testPayslip.encryptSensitiveData()
        
        // Then - Verify encryption was called
        XCTAssertEqual(mockEncryptionService.encryptionCount, 3)
        
        // Verify the sensitive data was encrypted
        XCTAssertNotEqual(testPayslip.name, "John Doe")
        XCTAssertNotEqual(testPayslip.accountNumber, "1234567890")
        XCTAssertNotEqual(testPayslip.panNumber, "ABCDE1234F")
        
        // When - Save to data service
        try await mockDataService.save(testPayslip)
        
        // Then - Verify save was called
        XCTAssertEqual(mockDataService.saveCount, 1)
        
        // When - Fetch from data service
        let fetchedPayslips = try await mockDataService.fetch(PayslipItem.self)
        
        // Then - Verify fetch was successful
        XCTAssertEqual(fetchedPayslips.count, 1)
        
        let fetchedPayslip = fetchedPayslips[0]
        
        // Verify the fetched payslip has encrypted data
        XCTAssertNotEqual(fetchedPayslip.name, "John Doe")
        XCTAssertNotEqual(fetchedPayslip.accountNumber, "1234567890")
        XCTAssertNotEqual(fetchedPayslip.panNumber, "ABCDE1234F")
        
        // When - Decrypt sensitive data
        try fetchedPayslip.decryptSensitiveData()
        
        // Then - Verify decryption was called
        XCTAssertEqual(mockEncryptionService.decryptionCount, 3)
        
        // Verify the sensitive data was decrypted back to original values
        XCTAssertEqual(fetchedPayslip.name, "John Doe")
        XCTAssertEqual(fetchedPayslip.accountNumber, "1234567890")
        XCTAssertEqual(fetchedPayslip.panNumber, "ABCDE1234F")
    }
    
    func testDataPersistenceAcrossAppRestarts() async throws {
        // Given - A payslip with encrypted sensitive data
        try testPayslip.encryptSensitiveData()
        try await mockDataService.save(testPayslip)
        
        // When - Simulate app restart by creating new services and container
        let newMockEncryptionService = MockEncryptionService()
        let newMockDataService = MockDataServiceHelper()
        
        // Copy the saved payslips to simulate persistence
        newMockDataService.testPayslips = mockDataService.testPayslips
        
        // Set up the factory to use our new mock
        _ = PayslipItem.setEncryptionServiceFactory { 
            return newMockEncryptionService as EncryptionServiceProtocolInternal
        }
        
        // Then - Fetch payslips after "restart"
        let fetchedPayslips = try await newMockDataService.fetch(PayslipItem.self)
        
        // Verify fetch was successful
        XCTAssertEqual(fetchedPayslips.count, 1)
        
        let fetchedPayslip = fetchedPayslips[0]
        
        // Verify the fetched payslip still has encrypted data
        XCTAssertNotEqual(fetchedPayslip.name, "John Doe")
        XCTAssertNotEqual(fetchedPayslip.accountNumber, "1234567890")
        XCTAssertNotEqual(fetchedPayslip.panNumber, "ABCDE1234F")
        
        // When - Decrypt sensitive data with new encryption service
        try fetchedPayslip.decryptSensitiveData()
        
        // Then - Verify decryption was called on the new service
        XCTAssertEqual(newMockEncryptionService.decryptionCount, 3)
        
        // Verify the sensitive data was decrypted back to original values
        XCTAssertEqual(fetchedPayslip.name, "John Doe")
        XCTAssertEqual(fetchedPayslip.accountNumber, "1234567890")
        XCTAssertEqual(fetchedPayslip.panNumber, "ABCDE1234F")
    }
    
    func testMultiplePayslipsPersistence() async throws {
        // Given - Create multiple payslips
        let payslip1 = PayslipItem(
            month: "January",
            year: 2023,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 500.0,
            tax: 800.0,
            name: "John Doe",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F"
        )
        
        let payslip2 = PayslipItem(
            month: "February",
            year: 2023,
            credits: 5500.0,
            debits: 1100.0,
            dsop: 550.0,
            tax: 850.0,
            name: "Jane Smith",
            accountNumber: "9876543210",
            panNumber: "ZYXWV9876G"
        )
        
        let payslip3 = PayslipItem(
            month: "March",
            year: 2023,
            credits: 6000.0,
            debits: 1200.0,
            dsop: 600.0,
            tax: 900.0,
            name: "Alex Johnson",
            accountNumber: "5678901234",
            panNumber: "PQRST5678H"
        )
        
        // When - Encrypt and save all payslips
        try payslip1.encryptSensitiveData()
        try payslip2.encryptSensitiveData()
        try payslip3.encryptSensitiveData()
        
        try await mockDataService.save(payslip1)
        try await mockDataService.save(payslip2)
        try await mockDataService.save(payslip3)
        
        // Then - Verify all payslips were saved
        XCTAssertEqual(mockDataService.saveCount, 3)
        
        // When - Fetch all payslips
        let fetchedPayslips = try await mockDataService.fetch(PayslipItem.self)
        
        // Then - Verify all payslips were fetched
        XCTAssertEqual(fetchedPayslips.count, 3)
        
        // Helper function to convert month name to number for sorting
        func monthToInt(_ month: String) -> Int {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM"
            guard let date = formatter.date(from: month) else { return 0 }
            let calendar = Calendar.current
            return calendar.component(.month, from: date)
        }
        
        // Sort payslips by month chronologically
        let sortedPayslips = fetchedPayslips.sorted { 
            monthToInt($0.month) < monthToInt($1.month)
        }
        
        // Decrypt and verify each payslip
        try sortedPayslips[0].decryptSensitiveData()
        try sortedPayslips[1].decryptSensitiveData()
        try sortedPayslips[2].decryptSensitiveData()
        
        // Verify first payslip (January)
        XCTAssertEqual(sortedPayslips[0].month, "January")
        XCTAssertEqual(sortedPayslips[0].name, "John Doe")
        XCTAssertEqual(sortedPayslips[0].accountNumber, "1234567890")
        
        // Verify second payslip (February)
        XCTAssertEqual(sortedPayslips[1].month, "February")
        XCTAssertEqual(sortedPayslips[1].name, "Jane Smith")
        XCTAssertEqual(sortedPayslips[1].accountNumber, "9876543210")
        
        // Verify third payslip (March)
        XCTAssertEqual(sortedPayslips[2].month, "March")
        XCTAssertEqual(sortedPayslips[2].name, "Alex Johnson")
        XCTAssertEqual(sortedPayslips[2].accountNumber, "5678901234")
    }
    
    func testDeletePayslip() async throws {
        // Given - A saved payslip with encrypted data
        try testPayslip.encryptSensitiveData()
        try await mockDataService.save(testPayslip)
        
        // When - Delete the payslip
        try await mockDataService.delete(testPayslip)
        
        // Then - Verify delete was called
        XCTAssertEqual(mockDataService.deleteCount, 1)
        
        // When - Fetch payslips
        let fetchedPayslips = try await mockDataService.fetch(PayslipItem.self)
        
        // Then - Verify no payslips are returned
        XCTAssertEqual(fetchedPayslips.count, 0)
    }
    
    func testErrorHandlingInDataPersistence() async throws {
        // Given - A payslip with sensitive data
        XCTAssertEqual(testPayslip.name, "John Doe")
        
        // When - Encryption service is set to fail
        mockEncryptionService.shouldFail = true
        
        // Then - Verify encryption throws an error
        XCTAssertThrowsError(try testPayslip.encryptSensitiveData()) { error in
            XCTAssertTrue(error is MockSecurityError)
            if let mockError = error as? MockSecurityError {
                XCTAssertEqual(mockError, MockSecurityError.encryptionFailed)
            }
        }
        
        // When - Data service is set to fail on save
        mockEncryptionService.shouldFail = false
        try testPayslip.encryptSensitiveData()
        mockDataService.shouldFailSave = true
        
        // Then - Verify save throws an error
        do {
            try await mockDataService.save(testPayslip)
            XCTFail("Save should have thrown an error")
        } catch {
            XCTAssertTrue(error is MockDataError)
            if let mockError = error as? MockDataError {
                XCTAssertEqual(mockError, MockDataError.saveFailed)
            }
        }
        
        // When - Data service is set to fail on fetch
        mockDataService.shouldFailSave = false
        try await mockDataService.save(testPayslip)
        mockDataService.shouldFailFetch = true
        
        // Then - Verify fetch throws an error
        do {
            _ = try await mockDataService.fetch(PayslipItem.self)
            XCTFail("Fetch should have thrown an error")
        } catch {
            XCTAssertTrue(error is MockDataError)
            if let mockError = error as? MockDataError {
                XCTAssertEqual(mockError, MockDataError.fetchFailed)
            }
        }
        
        // When - Data service is set to fail on delete
        mockDataService.shouldFailFetch = false
        mockDataService.shouldFailDelete = true
        
        // Then - Verify delete throws an error
        do {
            try await mockDataService.delete(testPayslip)
            XCTFail("Delete should have thrown an error")
        } catch {
            XCTAssertTrue(error is MockDataError)
            if let mockError = error as? MockDataError {
                XCTAssertEqual(mockError, MockDataError.deleteFailed)
            }
        }
    }
} 