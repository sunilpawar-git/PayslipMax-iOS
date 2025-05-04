import XCTest
import SwiftData
@testable import PayslipMax

final class PayslipMigrationTests: XCTestCase {
    // MARK: - Properties
    
    private var modelContainer: ModelContainer!
    private var modelContext: ModelContext!
    private var migrationManager: PayslipMigrationManager!
    
    // MARK: - Setup
    
    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: PayslipItem.self, configurations: config)
        modelContext = ModelContext(modelContainer)
        migrationManager = PayslipMigrationManager(modelContext: modelContext)
    }
    
    // MARK: - Tests
    
    func testMigrationToV2() async throws {
        // Create a V1 payslip item
        let payslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "January",
            year: 2023,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 200.0,
            tax: 800.0,
            earnings: [:],
            deductions: [:],
            name: "Test User",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F"
        )
        
        // Set to V1
        payslip.schemaVersion = PayslipSchemaVersion.v1.rawValue
        
        // Save the item
        modelContext.insert(payslip)
        try modelContext.save()
        
        // Perform migration
        try await migrationManager.migrate(item: payslip)
        
        // Verify migration results
        XCTAssertEqual(payslip.schemaVersion, PayslipSchemaVersion.v2.rawValue)
        XCTAssertNotNil(payslip.metadata)
        XCTAssertEqual(payslip.encryptionVersion, 2)
    }
    
    func testMigrationOfMultipleItems() async throws {
        // Create multiple V1 payslip items
        let items = (0..<5).map { index in
            PayslipItem(
                id: UUID(),
                timestamp: Date(),
                month: "January",
                year: 2023,
                credits: Double(5000 + index),
                debits: Double(1000 + index),
                dsop: Double(200 + index),
                tax: Double(800 + index),
                earnings: [:],
                deductions: [:],
                name: "Test User \(index)",
                accountNumber: "123456789\(index)",
                panNumber: "ABCDE1234\(index)"
            )
        }
        
        // Set all to V1
        items.forEach { $0.schemaVersion = PayslipSchemaVersion.v1.rawValue }
        
        // Save the items
        items.forEach { modelContext.insert($0) }
        try modelContext.save()
        
        // Perform migration
        try await migrationManager.migrate(items: items)
        
        // Verify migration results
        items.forEach {
            XCTAssertEqual($0.schemaVersion, PayslipSchemaVersion.v2.rawValue)
            XCTAssertNotNil($0.metadata)
            XCTAssertEqual($0.encryptionVersion, 2)
        }
    }
    
    func testMigrationOfAlreadyCurrentVersion() async throws {
        // Create a V2 payslip item
        let payslip = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "January",
            year: 2023,
            credits: 5000.0,
            debits: 1000.0,
            dsop: 200.0,
            tax: 800.0,
            earnings: [:],
            deductions: [:],
            name: "Test User",
            accountNumber: "1234567890",
            panNumber: "ABCDE1234F"
        )
        
        // Set to V2
        payslip.schemaVersion = PayslipSchemaVersion.v2.rawValue
        
        // Save the item
        modelContext.insert(payslip)
        try modelContext.save()
        
        // Perform migration
        try await migrationManager.migrate(item: payslip)
        
        // Verify no changes were made
        XCTAssertEqual(payslip.schemaVersion, PayslipSchemaVersion.v2.rawValue)
    }
} 