import XCTest
import SwiftData
@testable import PayslipMax

/// Test for DataServiceImpl core functionality
@MainActor
final class DataServiceTest: BaseTestCase {

    var modelContext: ModelContext!
    var mockSecurityService: MockSecurityService!
    var dataService: DataServiceImpl!

    override func setUp() {
        super.setUp()

        // Setup in-memory SwiftData with proper isolation
        do {
            let config = ModelConfiguration(
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none // Ensure no cloud persistence
            )
            let container = try ModelContainer(for: PayslipItem.self, configurations: config)
            modelContext = ModelContext(container)
            modelContext.undoManager = nil // Disable undo to prevent state retention

            // Create mock directly for type safety
            mockSecurityService = MockSecurityService()

            // Initialize DataServiceImpl with proper ModelContext
            dataService = DataServiceImpl(
                securityService: mockSecurityService,
                modelContext: modelContext
            )
        } catch {
            XCTFail("Failed to setup test environment: \(error)")
        }
    }

    override func tearDown() {
        // Explicitly clear all data before disposing context
        if let modelContext = modelContext {
            do {
                try modelContext.delete(model: PayslipItem.self)
                try modelContext.save()
            } catch {
                // Ignore cleanup errors in tearDown
            }
        }

        dataService = nil
        mockSecurityService = nil
        modelContext = nil
        super.tearDown()
    }

    func testDataServiceInitialization() async throws {
        // Test initial state
        XCTAssertFalse(dataService.isInitialized)

        // Test initialization
        try await dataService.initialize()
        XCTAssertTrue(dataService.isInitialized)
        XCTAssertTrue(mockSecurityService.isInitialized)
    }

    func testSavePayslipItem() async throws {
        try await dataService.initialize()
        let payslip = DataServiceTestHelpers.createTestPayslip(
            month: "January", year: 2024, credits: 6000.0, debits: 1200.0,
            dsop: 400.0, tax: 900.0, name: "Test Employee"
        )
        try await dataService.save(payslip)

        let savedPayslips: [PayslipItem] = try await dataService.fetch(PayslipItem.self)
        XCTAssertEqual(savedPayslips.count, 1)
        XCTAssertEqual(savedPayslips.first?.id, payslip.id)
        XCTAssertEqual(savedPayslips.first?.name, "Test Employee")
    }

    func testFetchPayslipItems() async throws {
        try await dataService.initialize()
        let payslip1 = DataServiceTestHelpers.createTestPayslip(
            month: "January", year: 2024, credits: 5000.0, debits: 1000.0,
            dsop: 300.0, tax: 700.0, name: "Test User 1"
        )
        let payslip2 = DataServiceTestHelpers.createTestPayslip(
            month: "February", year: 2024, credits: 5500.0, debits: 1100.0,
            dsop: 350.0, tax: 750.0, name: "Test User 2"
        )
        try await dataService.save(payslip1)
        try await dataService.save(payslip2)

        let payslips: [PayslipItem] = try await dataService.fetch(PayslipItem.self)
        XCTAssertEqual(payslips.count, 2)
        let payslipIds = Set(payslips.map { $0.id })
        XCTAssertTrue(payslipIds.contains(payslip1.id))
        XCTAssertTrue(payslipIds.contains(payslip2.id))
    }

    func testFetchRefreshedPayslipItems() async throws {
        try await dataService.initialize()
        let payslip = DataServiceTestHelpers.createTestPayslip(
            month: "March", year: 2024, credits: 4000.0, debits: 800.0,
            dsop: 200.0, tax: 600.0, name: "Refresh Test User"
        )
        try await dataService.save(payslip)

        let refreshedPayslips: [PayslipItem] = try await dataService.fetchRefreshed(PayslipItem.self)
        XCTAssertEqual(refreshedPayslips.count, 1)
        XCTAssertEqual(refreshedPayslips.first?.id, payslip.id)
    }

    func testProcessPendingChanges() async throws {
        try await dataService.initialize()
        dataService.processPendingChanges()
        XCTAssert(true, "Process pending changes completed without error")
    }

    func testSecurityServiceInitializationFailure() async {
        mockSecurityService.shouldFail = true
        do {
            try await dataService.initialize()
            XCTFail("Should have thrown an error when security service fails")
        } catch {
            XCTAssertFalse(dataService.isInitialized)
            XCTAssertEqual(error as? MockError, .initializationFailed)
        }
    }
}
