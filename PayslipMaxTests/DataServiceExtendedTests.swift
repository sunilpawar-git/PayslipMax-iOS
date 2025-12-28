import XCTest
import SwiftData
@testable import PayslipMax

/// Extended tests for DataServiceImpl - unsupported types, lazy init, and clear operations
@MainActor
final class DataServiceExtendedTests: BaseTestCase {

    var modelContext: ModelContext!
    var mockSecurityService: MockSecurityService!
    var dataService: DataServiceImpl!

    override func setUp() {
        super.setUp()

        do {
            let config = ModelConfiguration(
                isStoredInMemoryOnly: true,
                cloudKitDatabase: .none
            )
            let container = try ModelContainer(for: PayslipItem.self, configurations: config)
            modelContext = ModelContext(container)
            modelContext.undoManager = nil
            mockSecurityService = MockSecurityService()
            dataService = DataServiceImpl(
                securityService: mockSecurityService,
                modelContext: modelContext
            )
        } catch {
            XCTFail("Failed to setup test environment: \(error)")
        }
    }

    override func tearDown() {
        if let modelContext = modelContext {
            do {
                try modelContext.delete(model: PayslipItem.self)
                try modelContext.save()
            } catch {
                // Ignore cleanup errors
            }
        }
        dataService = nil
        mockSecurityService = nil
        modelContext = nil
        super.tearDown()
    }

    func testUnsupportedTypeOperations() async throws {
        try await dataService.initialize()

        struct UnsupportedTestType: Identifiable {
            let id = UUID()
            let name = "Test"
        }

        let unsupportedItem = UnsupportedTestType()

        do {
            try await dataService.save(unsupportedItem)
            XCTFail("Should have thrown an error for unsupported type")
        } catch DataError.unsupportedType {
            XCTAssert(true, "Correctly threw unsupported type error")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }

        do {
            let _: [UnsupportedTestType] = try await dataService.fetch(UnsupportedTestType.self)
            XCTFail("Should have thrown an error for unsupported type")
        } catch DataError.unsupportedType {
            XCTAssert(true, "Correctly threw unsupported type error")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testLazyInitialization() async throws {
        let newDataService = DataServiceImpl(
            securityService: mockSecurityService,
            modelContext: modelContext
        )
        XCTAssertFalse(newDataService.isInitialized)

        let payslip = DataServiceTestHelpers.createTestPayslip(
            month: "April", year: 2024, credits: 3000.0, debits: 600.0,
            dsop: 150.0, tax: 450.0, name: "Lazy Init Test"
        )

        try await newDataService.save(payslip)
        XCTAssertTrue(newDataService.isInitialized)

        let savedPayslips: [PayslipItem] = try await newDataService.fetch(PayslipItem.self)
        XCTAssertEqual(savedPayslips.count, 1)
        XCTAssertEqual(savedPayslips.first?.id, payslip.id)
    }

    func testClearAllData() async throws {
        try await dataService.initialize()

        let payslip1 = DataServiceTestHelpers.createTestPayslip(
            month: "May", year: 2024, credits: 7000.0, debits: 1400.0,
            dsop: 350.0, tax: 1050.0, name: "Clear Test 1"
        )
        let payslip2 = DataServiceTestHelpers.createTestPayslip(
            month: "June", year: 2024, credits: 7500.0, debits: 1500.0,
            dsop: 375.0, tax: 1125.0, name: "Clear Test 2"
        )

        try await dataService.save(payslip1)
        try await dataService.save(payslip2)

        let savedPayslips: [PayslipItem] = try await dataService.fetch(PayslipItem.self)
        XCTAssertEqual(savedPayslips.count, 2)

        try await dataService.clearAllData()

        let remainingPayslips: [PayslipItem] = try await dataService.fetch(PayslipItem.self)
        XCTAssertTrue(remainingPayslips.isEmpty)
    }
}

