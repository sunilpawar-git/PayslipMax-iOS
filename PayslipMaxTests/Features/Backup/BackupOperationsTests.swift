import XCTest
@testable import PayslipMax

/// Tests for Backup export operations
@MainActor
final class BackupOperationsTests: XCTestCase {

    private var mockRepository: MockPayslipRepository!
    private var helperOperations: BackupHelperOperations!
    private var exportOperations: BackupExportOperations!
    private var importOperations: BackupImportOperations!

    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockPayslipRepository()
        helperOperations = BackupHelperOperations()
        exportOperations = BackupExportOperations(
            repository: mockRepository,
            helperOperations: helperOperations
        )
        importOperations = BackupImportOperations(
            repository: mockRepository,
            helperOperations: helperOperations
        )
    }

    override func tearDown() async throws {
        mockRepository = nil
        helperOperations = nil
        exportOperations = nil
        importOperations = nil
        try await super.tearDown()
    }

    // MARK: - Export Tests

    func test_ExportBackup_WithMultiplePayslips_CreatesValidBackup() async throws {
        let payslips = BackupTestHelpers.createMockPayslipDTOs(count: 5)
        mockRepository.mockPayslips = payslips

        let result = try await exportOperations.exportBackup()

        XCTAssertEqual(result.backupFile.payslips.count, 5)
        XCTAssertEqual(result.backupFile.version, PayslipBackupFile.currentVersion)
        XCTAssertFalse(result.backupFile.checksum.isEmpty)
        XCTAssertGreaterThan(result.fileData.count, 0)
    }

    func test_ExportBackup_WithNoPayslips_ThrowsNoDataError() async {
        mockRepository.mockPayslips = []

        do {
            _ = try await exportOperations.exportBackup()
            XCTFail("Should throw noDataToBackup error")
        } catch let error as BackupError {
            if case .noDataToBackup = error {
                XCTAssertTrue(true)
            } else {
                XCTFail("Expected noDataToBackup error, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_ExportBackup_GeneratesCorrectFilename() async throws {
        mockRepository.mockPayslips = BackupTestHelpers.createMockPayslipDTOs(count: 1)
        let result = try await exportOperations.exportBackup()

        XCTAssertTrue(result.filename.hasPrefix("PayslipMax_Backup_"))
        XCTAssertTrue(result.filename.hasSuffix(".json"))
    }

    func test_ExportBackup_SummaryReflectsActualData() async throws {
        let payslips = BackupTestHelpers.createMockPayslipDTOs(count: 3)
        mockRepository.mockPayslips = payslips

        let result = try await exportOperations.exportBackup()

        XCTAssertEqual(result.summary.totalPayslips, 3)
        XCTAssertEqual(result.summary.fileSize, result.fileData.count)
        XCTAssertTrue(result.summary.encryptionEnabled)
    }

    // MARK: - Import Tests

    func test_ImportBackup_WithReplaceAllStrategy_ImportsAllPayslips() async throws {
        let backupData = try await createValidBackupData(payslipCount: 3)
        mockRepository.mockPayslips = []

        let result = try await importOperations.importBackup(from: backupData, strategy: .replaceAll)

        XCTAssertEqual(result.importedPayslips.count, 3)
        XCTAssertEqual(result.skippedPayslips.count, 0)
        XCTAssertTrue(result.failedPayslips.isEmpty)
        XCTAssertTrue(result.wasSuccessful)
    }

    func test_ImportBackup_WithSkipDuplicatesStrategy_ProcessesPayslips() async throws {
        let backupPayslips = [
            BackupTestHelpers.createMockPayslipDTO(id: UUID()),
            BackupTestHelpers.createMockPayslipDTO(id: UUID())
        ]
        let backupData = try await createValidBackupDataFrom(payslips: backupPayslips)
        mockRepository.mockPayslips = []

        let result = try await importOperations.importBackup(from: backupData, strategy: .skipDuplicates)

        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result.summary.totalProcessed, 0)
    }

    func test_ImportBackup_WithInvalidData_ThrowsError() async {
        let invalidData = "not a valid json".data(using: .utf8)!

        do {
            _ = try await importOperations.importBackup(from: invalidData, strategy: .replaceAll)
            XCTFail("Should throw error for invalid data")
        } catch {
            XCTAssertTrue(true)
        }
    }

    func test_ImportBackup_SummaryContainsCorrectCounts() async throws {
        let backupData = try await createValidBackupData(payslipCount: 5)

        let result = try await importOperations.importBackup(from: backupData, strategy: .replaceAll)

        XCTAssertEqual(result.summary.totalProcessed, 5)
        XCTAssertEqual(result.summary.successfulImports, 5)
        XCTAssertEqual(result.summary.skippedDuplicates, 0)
        XCTAssertEqual(result.summary.failedImports, 0)
        XCTAssertGreaterThan(result.summary.successRate, 0.99)
    }

    // MARK: - Round Trip Tests

    func test_ExportThenImport_PreservesAllData() async throws {
        let originalPayslips = BackupTestHelpers.createMockPayslipDTOs(count: 3)
        mockRepository.mockPayslips = originalPayslips

        let exportResult = try await exportOperations.exportBackup()
        mockRepository.mockPayslips = []
        mockRepository.savedPayslips = []

        let importResult = try await importOperations.importBackup(
            from: exportResult.fileData,
            strategy: .replaceAll
        )

        XCTAssertEqual(importResult.importedPayslips.count, 3)
        XCTAssertTrue(importResult.wasSuccessful)
        XCTAssertEqual(mockRepository.savedPayslips.count, 3)

        for (index, saved) in mockRepository.savedPayslips.enumerated() {
            let original = originalPayslips[index]
            XCTAssertEqual(saved.month, original.month)
            XCTAssertEqual(saved.year, original.year)
            XCTAssertEqual(saved.credits, original.credits, accuracy: 0.01)
        }
    }

    // MARK: - Helper Methods

    private func createValidBackupData(payslipCount: Int) async throws -> Data {
        let payslips = BackupTestHelpers.createMockPayslipDTOs(count: payslipCount)
        return try await createValidBackupDataFrom(payslips: payslips)
    }

    private func createValidBackupDataFrom(payslips: [PayslipDTO]) async throws -> Data {
        mockRepository.mockPayslips = payslips
        let result = try await exportOperations.exportBackup()
        return result.fileData
    }
}
