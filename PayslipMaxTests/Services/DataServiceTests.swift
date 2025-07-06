
import XCTest
import SwiftData
@testable import PayslipMax

class DataServiceTests: XCTestCase {
    
    var modelContext: ModelContext!
    var mockSecurityService: MockSecurityService!
    var mockPayslipRepository: MockPayslipRepository!
    var sut: DataServiceImpl!

    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // 1. Setup in-memory SwiftData
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PayslipItem.self, configurations: config)
        modelContext = ModelContext(container)
        
        // 2. Setup mocks
        mockSecurityService = MockSecurityService()
        mockPayslipRepository = MockPayslipRepository(modelContext: modelContext)
        
        // 3. Initialize System Under Test (SUT)
        sut = DataServiceImpl(
            securityService: mockSecurityService,
            modelContext: modelContext,
            payslipRepository: mockPayslipRepository
        )
    }

    override func tearDownWithError() throws {
        modelContext = nil
        mockSecurityService = nil
        mockPayslipRepository = nil
        sut = nil
        try super.tearDownWithError()
    }

    // MARK: - Initialization Tests

    func testInitialize_WhenSecurityServiceSucceeds_SetsIsInitialized() async throws {
        // Given
        XCTAssertFalse(sut.isInitialized)
        mockSecurityService.initializeShouldThrow = false

        // When
        try await sut.initialize()

        // Then
        XCTAssertTrue(sut.isInitialized)
        XCTAssertTrue(mockSecurityService.initializeCalled)
    }

    func testInitialize_WhenSecurityServiceFails_ThrowsErrorAndDoesNotInitialize() async {
        // Given
        mockSecurityService.initializeShouldThrow = true
        
        // When
        do {
            try await sut.initialize()
            XCTFail("Should have thrown an error")
        } catch {
            // Then
            XCTAssertFalse(sut.isInitialized)
            XCTAssertTrue(mockSecurityService.initializeCalled)
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
        XCTAssertTrue(mockSecurityService.initializeCalled)
        XCTAssertTrue(sut.isInitialized)
        XCTAssertTrue(mockPayslipRepository.savePayslipCalled)
    }

    func testSave_WithPayslipItem_CallsRepository() async throws {
        // Given
        try await sut.initialize()
        let payslip = PayslipItem.mock()
        
        // When
        try await sut.save(payslip)
        
        // Then
        XCTAssertTrue(mockPayslipRepository.savePayslipCalled)
        XCTAssertEqual(mockPayslipRepository.savedPayslip?.id, payslip.id)
    }

    func testSave_WithUnsupportedType_ThrowsError() async throws {
        // Given
        try await sut.initialize()
        struct UnsupportedItem: Identifiable { let id = UUID() }
        let item = UnsupportedItem()
        
        // When / Then
        do {
            try await sut.save(item)
            XCTFail("Should have thrown unsupportedType error")
        } catch DataServiceImpl.DataError.unsupportedType {
            // Success
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Fetch Tests

    func testFetch_WithPayslipItemType_CallsRepository() async throws {
        // Given
        try await sut.initialize()
        let expectedPayslips = [PayslipItem.mock(), PayslipItem.mock()]
        mockPayslipRepository.mockPayslips = expectedPayslips
        
        // When
        let fetchedPayslips: [PayslipItem] = try await sut.fetch(PayslipItem.self)
        
        // Then
        XCTAssertTrue(mockPayslipRepository.fetchAllPayslipsCalled)
        XCTAssertEqual(fetchedPayslips.count, 2)
    }

    func testFetch_WithUnsupportedType_ThrowsError() async throws {
        // Given
        try await sut.initialize()
        struct UnsupportedItem: Identifiable { let id = UUID() }
        
        // When / Then
        do {
            _ = try await sut.fetch(UnsupportedItem.self)
            XCTFail("Should have thrown unsupportedType error")
        } catch DataServiceImpl.DataError.unsupportedType {
            // Success
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Delete Tests

    func testDelete_WithPayslipItem_CallsRepository() async throws {
        // Given
        try await sut.initialize()
        let payslipToDelete = PayslipItem.mock()
        
        // When
        try await sut.delete(payslipToDelete)
        
        // Then
        XCTAssertTrue(mockPayslipRepository.deletePayslipCalled)
        XCTAssertEqual(mockPayslipRepository.deletedPayslip?.id, payslipToDelete.id)
    }

    // MARK: - Clear All Data Tests

    func testClearAllData_CallsRepository() async throws {
        // Given
        try await sut.initialize()
        
        // When
        try await sut.clearAllData()
        
        // Then
        XCTAssertTrue(mockPayslipRepository.deleteAllPayslipsCalled)
    }
}

// MARK: - Mock Implementations

class MockSecurityService: SecurityServiceProtocol {
    var isInitialized: Bool = false
    var initializeCalled = false
    var initializeShouldThrow = false

    func initialize() async throws {
        initializeCalled = true
        if initializeShouldThrow {
            throw MockError.initializationFailed
        }
        isInitialized = true
    }
}

class MockPayslipRepository: PayslipRepositoryProtocol {
    let modelContext: ModelContext
    var savePayslipCalled = false
    var savedPayslip: PayslipItem?
    var savePayslipsCalled = false
    var fetchAllPayslipsCalled = false
    var deletePayslipCalled = false
    var deletedPayslip: PayslipItem?
    var deleteAllPayslipsCalled = false
    
    var mockPayslips: [PayslipItem] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func savePayslip(_ payslip: PayslipItem) async throws {
        savePayslipCalled = true
        savedPayslip = payslip
    }

    func savePayslips(_ payslips: [PayslipItem]) async throws {
        savePayslipsCalled = true
    }

    func fetchAllPayslips() async throws -> [PayslipItem] {
        fetchAllPayslipsCalled = true
        return mockPayslips
    }

    func deletePayslip(_ payslip: PayslipItem) async throws {
        deletePayslipCalled = true
        deletedPayslip = payslip
    }
    
    func deletePayslips(_ payslips: [PayslipItem]) async throws {
        //
    }

    func deleteAllPayslips() async throws {
        deleteAllPayslipsCalled = true
    }
}

enum MockError: Error {
    case initializationFailed
}

extension PayslipItem {
    static func mock() -> PayslipItem {
        PayslipItem(id: UUID(), name: "Mock Payslip", data: Data())
    }
}

