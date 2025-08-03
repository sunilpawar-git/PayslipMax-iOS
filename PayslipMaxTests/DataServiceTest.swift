import XCTest
import SwiftData
@testable import PayslipMax

/// Test for DataServiceImpl core functionality
@MainActor
final class DataServiceTest: BaseTestCase {
    
    var modelContext: ModelContext!
    var mockSecurityService: CoreMockSecurityService!
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
            
            // Use registry for proper mock isolation
            mockSecurityService = MockServiceRegistry.shared.securityService
            
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
        // Initialize service
        try await dataService.initialize()
        
        // Create test payslip using proper constructor
        let payslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "January",
            year: 2024,
            credits: 6000.0,
            debits: 1200.0,
            dsop: 400.0,
            tax: 900.0,
            name: "Test Employee",
            accountNumber: "XXXX5678",
            panNumber: "ABCDE5678F",
            pdfData: Data()
        )
        
        // Test save operation - should work with proper ModelContext
        try await dataService.save(payslip)
        
        // Verify the payslip was saved by fetching it back
        let savedPayslips: [PayslipItem] = try await dataService.fetch(PayslipItem.self)
        XCTAssertEqual(savedPayslips.count, 1)
        XCTAssertEqual(savedPayslips.first?.id, payslip.id)
        XCTAssertEqual(savedPayslips.first?.name, "Test Employee")
    }
    
    func testFetchPayslipItems() async throws {
        // Initialize service
        try await dataService.initialize()
        
        // Create and save test payslips
        let payslip1 = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "January",
            year: 2024,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 300.0,
            tax: 700.0,
            name: "Test User 1",
            accountNumber: "123456789",
            panNumber: "ABCDE1234F",
            pdfData: Data()
        )
        
        let payslip2 = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "February",
            year: 2024,
            credits: 5500.0,
            debits: 1100.0,
            dsop: 350.0,
            tax: 750.0,
            name: "Test User 2",
            accountNumber: "987654321",
            panNumber: "FGHIJ5678K",
            pdfData: Data()
        )
        
        try await dataService.save(payslip1)
        try await dataService.save(payslip2)
        
        // Test fetch operation
        let payslips: [PayslipItem] = try await dataService.fetch(PayslipItem.self)
        XCTAssertEqual(payslips.count, 2)
        
        let payslipIds = Set(payslips.map { $0.id })
        XCTAssertTrue(payslipIds.contains(payslip1.id))
        XCTAssertTrue(payslipIds.contains(payslip2.id))
    }
    
    func testFetchRefreshedPayslipItems() async throws {
        // Initialize service
        try await dataService.initialize()
        
        // Create and save a test payslip
        let payslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "March",
            year: 2024,
            credits: 4000.0,
            debits: 800.0,
            dsop: 200.0,
            tax: 600.0,
            name: "Refresh Test User",
            accountNumber: "555666777",
            panNumber: "LMNOP9012Q",
            pdfData: Data()
        )
        
        try await dataService.save(payslip)
        
        // Test refreshed fetch operation
        let refreshedPayslips: [PayslipItem] = try await dataService.fetchRefreshed(PayslipItem.self)
        XCTAssertEqual(refreshedPayslips.count, 1)
        XCTAssertEqual(refreshedPayslips.first?.id, payslip.id)
    }
    
    func testUnsupportedTypeOperations() async throws {
        // Initialize service
        try await dataService.initialize()
        
        // Define an unsupported type for testing
        struct UnsupportedTestType: Identifiable {
            let id = UUID()
            let name = "Test"
        }
        
        let unsupportedItem = UnsupportedTestType()
        
        // Test save with unsupported type
        do {
            try await dataService.save(unsupportedItem)
            XCTFail("Should have thrown an error for unsupported type")
        } catch DataServiceImpl.DataError.unsupportedType {
            // Expected error for unsupported type
            XCTAssert(true, "Correctly threw unsupported type error")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        
        // Test fetch with unsupported type
        do {
            let _: [UnsupportedTestType] = try await dataService.fetch(UnsupportedTestType.self)
            XCTFail("Should have thrown an error for unsupported type")
        } catch DataServiceImpl.DataError.unsupportedType {
            // Expected error for unsupported type
            XCTAssert(true, "Correctly threw unsupported type error")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testLazyInitialization() async throws {
        // Create new service without manual initialization
        let newDataService = DataServiceImpl(
            securityService: mockSecurityService,
            modelContext: modelContext
        )
        XCTAssertFalse(newDataService.isInitialized)
        
        // Create a test payslip
        let payslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "April",
            year: 2024,
            credits: 3000.0,
            debits: 600.0,
            dsop: 150.0,
            tax: 450.0,
            name: "Lazy Init Test",
            accountNumber: "111222333",
            panNumber: "RSTUV3456W",
            pdfData: Data()
        )
        
        // Test that operations trigger lazy initialization
        try await newDataService.save(payslip)
        XCTAssertTrue(newDataService.isInitialized)
        
        // Verify the save worked
        let savedPayslips: [PayslipItem] = try await newDataService.fetch(PayslipItem.self)
        XCTAssertEqual(savedPayslips.count, 1)
        XCTAssertEqual(savedPayslips.first?.id, payslip.id)
    }
    
    func testProcessPendingChanges() async throws {
        // Initialize service
        try await dataService.initialize()
        
        // Test processPendingChanges doesn't throw
        dataService.processPendingChanges()
        XCTAssert(true, "Process pending changes completed without error")
    }
    
    func testClearAllData() async throws {
        // Initialize service
        try await dataService.initialize()
        
        // Create and save test payslips
        let payslip1 = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "May",
            year: 2024,
            credits: 7000.0,
            debits: 1400.0,
            dsop: 350.0,
            tax: 1050.0,
            name: "Clear Test 1",
            accountNumber: "777888999",
            panNumber: "XYZA1B2C3D",
            pdfData: Data()
        )
        
        let payslip2 = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "June",
            year: 2024,
            credits: 7500.0,
            debits: 1500.0,
            dsop: 375.0,
            tax: 1125.0,
            name: "Clear Test 2",
            accountNumber: "444555666",
            panNumber: "DEFG4H5I6J",
            pdfData: Data()
        )
        
        try await dataService.save(payslip1)
        try await dataService.save(payslip2)
        
        // Verify data exists
        let savedPayslips: [PayslipItem] = try await dataService.fetch(PayslipItem.self)
        XCTAssertEqual(savedPayslips.count, 2)
        
        // Clear all data
        try await dataService.clearAllData()
        
        // Verify all data was cleared
        let remainingPayslips: [PayslipItem] = try await dataService.fetch(PayslipItem.self)
        XCTAssertEqual(remainingPayslips.count, 0)
    }
    
    func testSecurityServiceInitializationFailure() async {
        // Configure mock to fail initialization
        mockSecurityService.shouldFail = true
        
        // Test that DataService initialization fails when SecurityService fails
        do {
            try await dataService.initialize()
            XCTFail("Should have thrown an error when security service fails")
        } catch {
            // Verify DataService is not initialized when SecurityService fails
            XCTAssertFalse(dataService.isInitialized)
            XCTAssertEqual(error as? MockError, .initializationFailed)
        }
    }
}