import XCTest
import SwiftData
@testable import PayslipMax

@MainActor
final class BackupChecksumEdgeCaseTests: XCTestCase {
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

    func testValidateBackup_rejectsCorruptedChecksum() async throws {
        // Seed some data and export a valid backup
        let p = PayslipItem(
            id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
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
        dataService.storedItems[String(describing: PayslipItem.self)] = [p]

        let export = try await backupService.exportBackup()

        // Decode JSON, tamper with checksum, then re-encode
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        var file = try dec.decode(PayslipBackupFile.self, from: export.fileData)
        file = PayslipBackupFile(
            version: file.version,
            exportDate: file.exportDate,
            deviceId: file.deviceId,
            encryptionVersion: file.encryptionVersion,
            userName: file.userName,
            payslips: file.payslips,
            metadata: file.metadata,
            checksum: "deadbeef"
        )
        let enc = JSONEncoder()
        enc.outputFormatting = [.sortedKeys]
        enc.dateEncodingStrategy = .iso8601
        let tampered = try enc.encode(file)

        await XCTAssertThrowsErrorAsync(try await backupService.validateBackup(data: tampered)) { error in
            if let be = error as? BackupError {
                switch be {
                case .checksumMismatch:
                    break
                default:
                    XCTFail("Expected checksumMismatch, got: \(be)")
                }
            } else {
                XCTFail("Expected BackupError, got: \(error)")
            }
        }
    }

    func testValidateBackup_ignoresUnknownFields_localeSafe() async throws {
        // Export a valid backup
        let p = PayslipItem(
            id: UUID(),
            timestamp: Date(timeIntervalSince1970: 1_700_010_000),
            month: "Feb",
            year: 2024,
            credits: 1200,
            debits: 250,
            dsop: 60,
            tax: 120,
            earnings: ["BPAY": 1200],
            deductions: ["ITAX": 120]
        )
        dataService.storedItems[String(describing: PayslipItem.self)] = [p]
        let export = try await backupService.exportBackup()

        // Inject unknown field and ensure validate still succeeds
        var json = try JSONSerialization.jsonObject(with: export.fileData, options: []) as! [String: Any]
        json["unknown_field"] = "safe"
        let mutated = try JSONSerialization.data(withJSONObject: json, options: [.sortedKeys])

        let validated = try await backupService.validateBackup(data: mutated)
        XCTAssertEqual(validated.metadata.totalPayslips, 1)
    }
}

// Async throws helper
func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ errorHandler: (_ error: Error) -> Void = { _ in }
) async {
    do {
        _ = try await expression()
        XCTFail("Expected error to be thrown. " + message(), file: file, line: line)
    } catch {
        errorHandler(error)
    }
}


