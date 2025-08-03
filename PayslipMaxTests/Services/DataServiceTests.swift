
import XCTest
import SwiftData
@testable import PayslipMax

@MainActor
class DataServiceTests: BaseTestCase {
    
    var modelContext: ModelContext!
    var mockSecurityService: CoreMockSecurityService!
    var sut: DataServiceImpl!

    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // 1. Setup in-memory SwiftData with unique identifier for test isolation
        let config = ModelConfiguration(
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none // Ensure no cloud persistence
        )
        let container = try ModelContainer(for: PayslipItem.self, configurations: config)
        modelContext = ModelContext(container)
        modelContext.undoManager = nil // Disable undo to prevent state retention
        
        // 2. Setup mocks using registry for proper isolation
        mockSecurityService = MockServiceRegistry.shared.securityService
        
        // 3. Initialize System Under Test (SUT)
        sut = DataServiceImpl(
            securityService: mockSecurityService,
            modelContext: modelContext
        )
    }

    override func tearDownWithError() throws {
        // Explicitly clear all data before disposing context
        if let modelContext = modelContext {
            do {
                try modelContext.delete(model: PayslipItem.self)
                try modelContext.save()
            } catch {
                // Ignore cleanup errors in tearDown
            }
        }
        
        modelContext = nil
        mockSecurityService = nil
        sut = nil
        try super.tearDownWithError()
    }

    // MARK: - Initialization Tests

    func testInitialize_WhenSecurityServiceSucceeds_SetsIsInitialized() async throws {
        // Given
        XCTAssertFalse(sut.isInitialized)
        mockSecurityService.shouldFail = false

        // When
        try await sut.initialize()

        // Then
        XCTAssertTrue(sut.isInitialized)
        XCTAssertTrue(mockSecurityService.isInitialized)
    }

    func testInitialize_WhenSecurityServiceFails_ThrowsErrorAndDoesNotInitialize() async {
        // Given
        mockSecurityService.shouldFail = true
        
        // When
        do {
            try await sut.initialize()
            XCTFail("Should have thrown an error")
        } catch {
            // Then
            XCTAssertFalse(sut.isInitialized)
            XCTAssertFalse(mockSecurityService.isInitialized)
            XCTAssertEqual(error as? MockError, .initializationFailed)
        }
    }

    // MARK: - Save Tests

    func testSave_WhenNotInitialized_InitializesFirst() async throws {
        // Given
        let payslip = PayslipItem.mock()
        
        // When
        try await sut.save(payslip)
        
        // Then
        XCTAssertTrue(mockSecurityService.isInitialized)
        XCTAssertTrue(sut.isInitialized)
        
        // Verify the item was saved by fetching it back
        let savedPayslips: [PayslipItem] = try await sut.fetch(PayslipItem.self)
        XCTAssertEqual(savedPayslips.count, 1)
        XCTAssertEqual(savedPayslips.first?.id, payslip.id)
    }

    func testSave_WithPayslipItem_SavesSuccessfully() async throws {
        // Given
        try await sut.initialize()
        let payslip = PayslipItem.mock()
        
        // When
        try await sut.save(payslip)
        
        // Then - Verify the item was saved by fetching it back
        let savedPayslips: [PayslipItem] = try await sut.fetch(PayslipItem.self)
        XCTAssertEqual(savedPayslips.count, 1)
        XCTAssertEqual(savedPayslips.first?.id, payslip.id)
    }

    func testSave_WithUnsupportedType_ThrowsError() async throws {
        // Given
        try await sut.initialize()
        struct UnsupportedItem: Identifiable { let id = UUID() }
        let unsupportedItem = UnsupportedItem()
        
        // When & Then
        do {
            try await sut.save(unsupportedItem)
            XCTFail("Should have thrown an error")
        } catch {
            // Expected to throw an error for unsupported type
            XCTAssertTrue(error is DataServiceImpl.DataError)
            if case DataServiceImpl.DataError.unsupportedType = error {
                // Success - correct error type
            } else {
                XCTFail("Expected unsupportedType error, got \(error)")
            }
        }
    }

    // MARK: - Fetch Tests

    func testFetch_ReturnsAllPayslips() async throws {
        // Given
        try await sut.initialize()
        let payslip1 = PayslipItem.mock()
        let payslip2 = PayslipItem.mock()
        
        // Save test data
        try await sut.save(payslip1)
        try await sut.save(payslip2)
        
        // When
        let result: [PayslipItem] = try await sut.fetch(PayslipItem.self)
        
        // Then
        XCTAssertEqual(result.count, 2)
        let resultIds = Set(result.map { $0.id })
        XCTAssertTrue(resultIds.contains(payslip1.id))
        XCTAssertTrue(resultIds.contains(payslip2.id))
    }

    func testFetch_WithUnsupportedType_ThrowsError() async throws {
        // Given
        try await sut.initialize()
        struct UnsupportedItem: Identifiable { let id = UUID() }
        
        // When & Then
        do {
            let _: [UnsupportedItem] = try await sut.fetch(UnsupportedItem.self)
            XCTFail("Should have thrown an error")
        } catch {
            // Expected to throw an error for unsupported type
            XCTAssertTrue(error is DataServiceImpl.DataError)
            if case DataServiceImpl.DataError.unsupportedType = error {
                // Success - correct error type
            } else {
                XCTFail("Expected unsupportedType error, got \(error)")
            }
        }
    }

    // MARK: - Delete Tests

    func testDelete_WithPayslipItem_DeletesSuccessfully() async throws {
        // Given
        try await sut.initialize()
        let payslip = PayslipItem.mock()
        
        // Save the item first
        try await sut.save(payslip)
        
        // Verify it was saved
        let savedPayslips: [PayslipItem] = try await sut.fetch(PayslipItem.self)
        XCTAssertEqual(savedPayslips.count, 1)
        
        // When
        try await sut.delete(payslip)
        
        // Then - Verify it was deleted
        let remainingPayslips: [PayslipItem] = try await sut.fetch(PayslipItem.self)
        XCTAssertEqual(remainingPayslips.count, 0)
    }

    func testDelete_WithUnsupportedType_ThrowsError() async throws {
        // Given
        try await sut.initialize()
        struct UnsupportedItem: Identifiable { let id = UUID() }
        let unsupportedItem = UnsupportedItem()
        
        // When & Then
        do {
            try await sut.delete(unsupportedItem)
            XCTFail("Should have thrown an error")
        } catch {
            // Expected to throw an error for unsupported type
            XCTAssertTrue(error is DataServiceImpl.DataError)
            if case DataServiceImpl.DataError.unsupportedType = error {
                // Success - correct error type
            } else {
                XCTFail("Expected unsupportedType error, got \(error)")
            }
        }
    }

    // MARK: - Clear All Tests

    func testClearAllData_DeletesAllPayslips() async throws {
        // Given
        try await sut.initialize()
        let payslip1 = PayslipItem.mock()
        let payslip2 = PayslipItem.mock()
        
        // Save test data
        try await sut.save(payslip1)
        try await sut.save(payslip2)
        
        // Verify data exists
        let savedPayslips: [PayslipItem] = try await sut.fetch(PayslipItem.self)
        XCTAssertEqual(savedPayslips.count, 2)
        
        // When
        try await sut.clearAllData()
        
        // Then - Verify all data was deleted
        let remainingPayslips: [PayslipItem] = try await sut.fetch(PayslipItem.self)
        XCTAssertEqual(remainingPayslips.count, 0)
    }
}

extension PayslipItem {
    static func mock() -> PayslipItem {
        PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "January",
            year: 2023,
            credits: 10000.0,
            debits: 2000.0,
            dsop: 500.0,
            tax: 1000.0,
            name: "Mock User",
            accountNumber: "123456789",
            panNumber: "ABCDE1234F",
            pdfData: Data()
        )
    }
}

