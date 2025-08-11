import XCTest
import SwiftData
@testable import PayslipMax

@MainActor
final class BackupServiceDeterminismTests: XCTestCase {
    private var modelContext: ModelContext!
    private var dataService: MockDataService!
    private var backupService: BackupService!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: PayslipItem.self, configurations: config)
        modelContext = ModelContext(container)
        dataService = MockDataService()
        backupService = BackupService(dataService: dataService, secureDataManager: SecureDataManager(), modelContext: modelContext)
    }

    func testExportImportChecksumRoundTrip_IsDeterministic() async throws {
        // Given two payslips inserted in non-deterministic order
        let p1 = PayslipItem(
            id: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            timestamp: Date(timeIntervalSince1970: 1_700_000_000),
            month: "Jan",
            year: 2024,
            credits: 1000,
            debits: 200,
            dsop: 50,
            tax: 100,
            earnings: ["BPAY": 1000],
            deductions: ["ITAX": 100]
        )
        let p2 = PayslipItem(
            id: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
            timestamp: Date(timeIntervalSince1970: 1_700_000_100),
            month: "Feb",
            year: 2024,
            credits: 1100,
            debits: 210,
            dsop: 55,
            tax: 110,
            earnings: ["BPAY": 1100],
            deductions: ["ITAX": 110]
        )

        // Insert in shuffled order to verify sorting is applied
        dataService.storedItems[String(describing: PayslipItem.self)] = [p2, p1]

        // When exporting backup
        let export1 = try await backupService.exportBackup()

        // Import back using validate path to ensure checksum is enforced
        let validated = try await backupService.validateBackup(data: export1.fileData)
        XCTAssertEqual(validated.checksum.isEmpty, false)

        // Export again without changing data; checksum must match
        dataService.storedItems[String(describing: PayslipItem.self)] = [p1, p2]
        let export2 = try await backupService.exportBackup()

        XCTAssertEqual(export1.backupFile.checksum, export2.backupFile.checksum, "Checksums should be identical for same logical data")
        // Note: exportDate will differ across runs; raw bytes may differ even with deterministic canonical fields
    }

    func testLargeBackupPerformance() async throws {
        // Generate 1200 payslips
        var items: [PayslipItem] = []
        items.reserveCapacity(1200)
        for i in 0..<1200 {
            let item = PayslipItem(
                id: UUID(),
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

        let expectation = XCTestExpectation(description: "export completes under budget")
        let start = Date()
        Task { @MainActor in
            do {
                _ = try await self.backupService.exportBackup()
                expectation.fulfill()
            } catch {
                XCTFail("Export failed: \(error)")
            }
        }
        await fulfillment(of: [expectation], timeout: 60.0)
        let elapsed = Date().timeIntervalSince(start)
        XCTAssertLessThan(elapsed, 60.0, "Large backup export should complete within 60s on CI simulator")
    }
}


