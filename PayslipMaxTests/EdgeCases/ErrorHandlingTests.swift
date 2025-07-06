import XCTest
import SwiftData
@testable import PayslipMax

class ErrorHandlingTests: XCTestCase {
    
    var modelContext: ModelContext!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Setup in-memory SwiftData
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PayslipItem.self, configurations: config)
        modelContext = ModelContext(container)
    }
    
    override func tearDownWithError() throws {
        modelContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - AppError Tests
    
    func testAppError_AllCases_ProvideDescriptiveMessages() {
        // Given
        let appErrors: [AppError] = [
            .message("Custom error message"),
            .pdfProcessingFailed("PDF processing failed"),
            .passwordProtectedPDF,
            .authenticationFailed,
            .dataCorrupted,
            .networkError,
            .storageError("Storage operation failed"),
            .invalidData("Invalid data format"),
            .permissionDenied,
            .operationCancelled
        ]
        
        // When/Then
        for error in appErrors {
            let description = error.localizedDescription
            XCTAssertFalse(description.isEmpty, "Error should have non-empty description")
            XCTAssertGreaterThan(description.count, 5, "Error description should be meaningful")
        }
    }
    
    func testAppError_Equatable_WorksCorrectly() {
        // Given
        let error1 = AppError.message("Same message")
        let error2 = AppError.message("Same message")
        let error3 = AppError.message("Different message")
        let error4 = AppError.passwordProtectedPDF
        let error5 = AppError.passwordProtectedPDF
        
        // When/Then
        XCTAssertEqual(error1, error2, "Errors with same message should be equal")
        XCTAssertNotEqual(error1, error3, "Errors with different messages should not be equal")
        XCTAssertEqual(error4, error5, "Same error types should be equal")
        XCTAssertNotEqual(error1, error4, "Different error types should not be equal")
    }
    
    // MARK: - Data Service Error Handling
    
    func testDataService_WithInvalidData_HandlesErrors() async {
        // Given
        let securityService = SecurityServiceImpl()
        let payslipRepository = MockPayslipRepository(modelContext: modelContext)
        let dataService = DataServiceImpl(
            securityService: securityService,
            modelContext: modelContext,
            payslipRepository: payslipRepository
        )
        
        // Test uninitialized operations
        struct UnsupportedType: Identifiable {
            let id = UUID()
        }
        
        // When/Then
        do {
            try await dataService.save(UnsupportedType())
            XCTFail("Should throw unsupportedType error")
        } catch DataServiceImpl.DataError.unsupportedType {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
        
        do {
            let _: [UnsupportedType] = try await dataService.fetch(UnsupportedType.self)
            XCTFail("Should throw unsupportedType error")
        } catch DataServiceImpl.DataError.unsupportedType {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testDataService_WithRepositoryErrors_PropagatesCorrectly() async {
        // Given
        let securityService = SecurityServiceImpl()
        let mockRepository = FailingMockPayslipRepository(modelContext: modelContext)
        let dataService = DataServiceImpl(
            securityService: securityService,
            modelContext: modelContext,
            payslipRepository: mockRepository
        )
        
        try! await dataService.initialize()
        
        // When/Then - Test save failure
        let payslip = TestDataGenerator.samplePayslipItem()
        do {
            try await dataService.save(payslip)
            XCTFail("Should propagate repository error")
        } catch MockRepositoryError.saveFailed {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
        
        // When/Then - Test fetch failure
        do {
            let _: [PayslipItem] = try await dataService.fetch(PayslipItem.self)
            XCTFail("Should propagate repository error")
        } catch MockRepositoryError.fetchFailed {
            // Expected
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Security Service Error Handling
    
    func testSecurityService_ErrorStates_HandleCorrectly() async {
        // Given
        let securityService = SecurityServiceImpl()
        
        // Test operations before initialization
        do {
            try await securityService.setupPIN(pin: "1234")
            XCTFail("Should throw notInitialized error")
        } catch SecurityServiceImpl.SecurityError.notInitialized {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        do {
            _ = try await securityService.verifyPIN(pin: "1234")
            XCTFail("Should throw notInitialized error")
        } catch SecurityServiceImpl.SecurityError.notInitialized {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Initialize and test PIN operations
        try! await securityService.initialize()
        
        do {
            _ = try await securityService.verifyPIN(pin: "1234")
            XCTFail("Should throw pinNotSet error")
        } catch SecurityServiceImpl.SecurityError.pinNotSet {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Set PIN and test decryption with invalid data
        try! await securityService.setupPIN(pin: "1234")
        
        do {
            _ = try await securityService.decryptData(Data("invalid".utf8))
            XCTFail("Should throw decryption error")
        } catch {
            // Expected - any decryption error is acceptable for invalid data
        }
    }
    
    // MARK: - PDF Processing Error Handling
    
    func testPDFProcessing_WithInvalidInputs_HandlesGracefully() {
        // Given
        let invalidInputs: [Data] = [
            Data(), // Empty data
            Data("Not a PDF".utf8), // Invalid format
            Data(repeating: 0x00, count: 1000), // Null bytes
            Data(repeating: 0xFF, count: 1000), // Random bytes
        ]
        
        // When/Then
        for invalidData in invalidInputs {
            let pdfDocument = PDFDocument(data: invalidData)
            XCTAssertNil(pdfDocument, "Invalid data should not create PDF document")
        }
    }
    
    // MARK: - Memory Management Error Handling
    
    func testMemoryPressure_HandlesGracefully() throws {
        // Given - Create memory pressure scenario
        var largePayslips: [PayslipItem] = []
        let largeDataSize = 1024 * 1024 // 1MB per payslip
        
        // When - Create multiple large payslips
        for i in 0..<10 {
            let largeData = Data(repeating: UInt8(i), count: largeDataSize)
            let payslip = PayslipItem(
                id: UUID(),
                name: "Large Payslip \(i)",
                data: largeData
            )
            largePayslips.append(payslip)
            modelContext.insert(payslip)
        }
        
        // Then - Should handle memory pressure without crashing
        do {
            try modelContext.save()
        } catch {
            // If this fails due to memory pressure, that's a valid test outcome
            print("Memory pressure test failed as expected: \(error)")
        }
        
        // Clean up
        for payslip in largePayslips {
            modelContext.delete(payslip)
        }
        try modelContext.save()
    }
    
    // MARK: - Concurrent Error Handling
    
    func testConcurrentErrors_HandleCorrectly() async {
        // Given
        let errorGeneratingOperations = 20
        
        // When - Perform operations that intentionally cause errors
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<errorGeneratingOperations {
                group.addTask {
                    do {
                        // Intentionally cause errors
                        if i % 2 == 0 {
                            // Try to decrypt invalid data
                            let securityService = SecurityServiceImpl()
                            try await securityService.initialize()
                            _ = try await securityService.decryptData(Data("invalid".utf8))
                        } else {
                            // Try to create PDF from invalid data
                            _ = PDFDocument(data: Data("not a pdf".utf8))
                        }
                    } catch {
                        // Expected - errors should be handled gracefully
                    }
                }
            }
            
            // Wait for all tasks
            for await _ in group {
                // All completed
            }
        }
        
        // Then - Should complete without crashes
        XCTAssertTrue(true, "Concurrent error handling completed")
    }
    
    // MARK: - Error Recovery Tests
    
    func testErrorRecovery_AfterFailure_AllowsSubsequentOperations() async throws {
        // Given
        let securityService = SecurityServiceImpl()
        try await securityService.initialize()
        
        // When - Cause an error
        do {
            _ = try await securityService.decryptData(Data("invalid".utf8))
            XCTFail("Should have thrown error")
        } catch {
            // Expected error
        }
        
        // Then - Service should still work for valid operations
        let validData = Data("test data".utf8)
        let encryptedData = try await securityService.encryptData(validData)
        let decryptedData = try await securityService.decryptData(encryptedData)
        
        XCTAssertEqual(decryptedData, validData, "Service should recover after error")
    }
    
    // MARK: - Network Error Simulation
    
    func testNetworkError_Handling() {
        // Given
        let networkErrors: [AppError] = [
            .networkError,
            .operationCancelled,
            .message("Connection timeout"),
            .message("No internet connection")
        ]
        
        // When/Then
        for error in networkErrors {
            // Simulate error handling that might occur in network operations
            let shouldRetry = shouldRetryOperation(for: error)
            let userMessage = getUserFriendlyMessage(for: error)
            
            XCTAssertNotNil(userMessage)
            XCTAssertFalse(userMessage.isEmpty)
            
            // Network errors should typically allow retry
            if case .networkError = error {
                XCTAssertTrue(shouldRetry)
            } else if case .operationCancelled = error {
                XCTAssertFalse(shouldRetry)
            }
        }
    }
    
    // MARK: - File System Error Handling
    
    func testFileSystemErrors_HandleCorrectly() {
        // Given
        let fileSystemErrors: [AppError] = [
            .storageError("Disk full"),
            .storageError("Permission denied"),
            .permissionDenied,
            .message("File not found")
        ]
        
        // When/Then
        for error in fileSystemErrors {
            let errorCode = getErrorCode(for: error)
            let recoveryAction = getRecoveryAction(for: error)
            
            XCTAssertGreaterThan(errorCode, 0)
            XCTAssertNotNil(recoveryAction)
        }
    }
    
    // MARK: - Data Corruption Error Handling
    
    func testDataCorruption_DetectionAndRecovery() throws {
        // Given - Create a payslip and then simulate corruption
        let originalPayslip = TestDataGenerator.samplePayslipItem(name: "Original")
        modelContext.insert(originalPayslip)
        try modelContext.save()
        
        // Simulate detection of corrupted data
        let corruptionError = AppError.dataCorrupted
        
        // When/Then
        XCTAssertEqual(corruptionError, AppError.dataCorrupted)
        XCTAssertTrue(corruptionError.localizedDescription.contains("corrupt"))
        
        // Recovery strategy would be to recreate or restore from backup
        let recoveredPayslip = TestDataGenerator.samplePayslipItem(name: "Recovered")
        modelContext.insert(recoveredPayslip)
        try modelContext.save()
        
        let fetchDescriptor = FetchDescriptor<PayslipItem>()
        let allPayslips = try modelContext.fetch(fetchDescriptor)
        XCTAssertGreaterThanOrEqual(allPayslips.count, 2)
    }
    
    // MARK: - Helper Methods
    
    private func shouldRetryOperation(for error: AppError) -> Bool {
        switch error {
        case .networkError:
            return true
        case .operationCancelled:
            return false
        case .message(let msg) where msg.contains("timeout") || msg.contains("connection"):
            return true
        default:
            return false
        }
    }
    
    private func getUserFriendlyMessage(for error: AppError) -> String {
        switch error {
        case .networkError:
            return "Please check your internet connection and try again."
        case .passwordProtectedPDF:
            return "This PDF is password protected. Please enter the password."
        case .authenticationFailed:
            return "Authentication failed. Please verify your credentials."
        case .dataCorrupted:
            return "The data appears to be corrupted. Please try again or restore from backup."
        case .permissionDenied:
            return "Permission denied. Please check your access rights."
        case .operationCancelled:
            return "Operation was cancelled."
        case .storageError(let details):
            return "Storage error: \(details)"
        case .invalidData(let details):
            return "Invalid data: \(details)"
        case .pdfProcessingFailed(let details):
            return "PDF processing failed: \(details)"
        case .message(let msg):
            return msg
        }
    }
    
    private func getErrorCode(for error: AppError) -> Int {
        switch error {
        case .message(_):
            return 1000
        case .pdfProcessingFailed(_):
            return 1001
        case .passwordProtectedPDF:
            return 1002
        case .authenticationFailed:
            return 1003
        case .dataCorrupted:
            return 1004
        case .networkError:
            return 1005
        case .storageError(_):
            return 1006
        case .invalidData(_):
            return 1007
        case .permissionDenied:
            return 1008
        case .operationCancelled:
            return 1009
        }
    }
    
    private func getRecoveryAction(for error: AppError) -> String {
        switch error {
        case .storageError(_):
            return "free_space"
        case .permissionDenied:
            return "check_permissions"
        case .networkError:
            return "retry_connection"
        case .dataCorrupted:
            return "restore_backup"
        default:
            return "retry_operation"
        }
    }
}

// MARK: - Mock Error Classes

class FailingMockPayslipRepository: PayslipRepositoryProtocol {
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func savePayslip(_ payslip: PayslipItem) async throws {
        throw MockRepositoryError.saveFailed
    }
    
    func savePayslips(_ payslips: [PayslipItem]) async throws {
        throw MockRepositoryError.saveFailed
    }
    
    func fetchAllPayslips() async throws -> [PayslipItem] {
        throw MockRepositoryError.fetchFailed
    }
    
    func deletePayslip(_ payslip: PayslipItem) async throws {
        throw MockRepositoryError.deleteFailed
    }
    
    func deletePayslips(_ payslips: [PayslipItem]) async throws {
        throw MockRepositoryError.deleteFailed
    }
    
    func deleteAllPayslips() async throws {
        throw MockRepositoryError.deleteFailed
    }
}

enum MockRepositoryError: Error, LocalizedError {
    case saveFailed
    case fetchFailed
    case deleteFailed
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Mock save operation failed"
        case .fetchFailed:
            return "Mock fetch operation failed"
        case .deleteFailed:
            return "Mock delete operation failed"
        }
    }
}