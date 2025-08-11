import XCTest
import SwiftData
@testable import PayslipMax

@MainActor
final class BackupRoundTripLargeDatasetTests: XCTestCase {
    private var modelContext: ModelContext!
    private var dataService: MockDataService!
    private var backupService: BackupService!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PayslipItem.self, configurations: config)
        modelContext = ModelContext(container)
        dataService = MockDataService()
        backupService = BackupService(
            dataService: dataService,
            secureDataManager: SecureDataManager(),
            modelContext: modelContext
        )
    }

    func testRoundTrip_10000Items_ProducesStableChecksumWithinMemoryBudget() async throws {
        // Generate 10,000 payslips deterministically
        var items: [PayslipItem] = []
        items.reserveCapacity(10_000)
        for i in 0..<10_000 {
            let item = PayslipItem(
                id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", i)) ?? UUID(),
                timestamp: Date(timeIntervalSince1970: 1_700_000_000 + TimeInterval(i)),
                month: "M\(i % 12)",
                year: 2024,
                credits: Double(1000 + i),
                debits: Double(200 + (i % 50)),
                dsop: Double(50 + (i % 10)),
                tax: Double(100 + (i % 30)),
                earnings: ["BPAY": Double(1000 + i)],
                deductions: ["ITAX": Double(100 + (i % 30))]
            )
            items.append(item)
        }
        dataService.storedItems[String(describing: PayslipItem.self)] = items

        // Export → Import → Export
        let export1 = try await backupService.exportBackup()
        let validated = try await backupService.validateBackup(data: export1.fileData)
        XCTAssertFalse(validated.checksum.isEmpty)

        // Clear and import back
        dataService.storedItems[String(describing: PayslipItem.self)] = []
        let importResult = try await backupService.importBackup(from: export1.fileData, strategy: .replaceAll)
        XCTAssertEqual(importResult.summary.successfulImports, 10_000)

        // Re-export and compare checksum
        let export2 = try await backupService.exportBackup()
        XCTAssertEqual(export1.backupFile.checksum, export2.backupFile.checksum)

        // Simple memory budget heuristic: file size should be < 50 MB
        XCTAssertLessThan(export1.fileData.count, 50 * 1024 * 1024)
    }
}


