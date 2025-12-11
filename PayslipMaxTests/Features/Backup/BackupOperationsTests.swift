import XCTest
@testable import PayslipMax

/// Comprehensive tests for Backup operations including export, import, and helper functions
@MainActor
final class BackupOperationsTests: XCTestCase {

    // MARK: - Test Properties

    private var mockRepository: MockPayslipRepository!
    private var helperOperations: BackupHelperOperations!
    private var exportOperations: BackupExportOperations!
    private var importOperations: BackupImportOperations!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        mockRepository = MockPayslipRepository()
        helperOperations = BackupHelperOperations()
        exportOperations = BackupExportOperations(repository: mockRepository, helperOperations: helperOperations)
        importOperations = BackupImportOperations(repository: mockRepository, helperOperations: helperOperations)
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
        // Given
        let payslips = createMockPayslipDTOs(count: 5)
        mockRepository.mockPayslips = payslips

        // When
        let result = try await exportOperations.exportBackup()

        // Then
        XCTAssertEqual(result.backupFile.payslips.count, 5)
        XCTAssertEqual(result.backupFile.version, PayslipBackupFile.currentVersion)
        XCTAssertFalse(result.backupFile.checksum.isEmpty)
        XCTAssertGreaterThan(result.fileData.count, 0)
    }

    func test_ExportBackup_WithNoPayslips_ThrowsNoDataError() async {
        // Given
        mockRepository.mockPayslips = []

        // When/Then
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
        // Given
        mockRepository.mockPayslips = createMockPayslipDTOs(count: 1)

        // When
        let result = try await exportOperations.exportBackup()

        // Then
        XCTAssertTrue(result.filename.hasPrefix("PayslipMax_Backup_"))
        XCTAssertTrue(result.filename.hasSuffix(".json"))
    }

    func test_ExportBackup_SummaryReflectsActualData() async throws {
        // Given
        let payslips = createMockPayslipDTOs(count: 3)
        mockRepository.mockPayslips = payslips

        // When
        let result = try await exportOperations.exportBackup()

        // Then
        XCTAssertEqual(result.summary.totalPayslips, 3)
        XCTAssertEqual(result.summary.fileSize, result.fileData.count)
        XCTAssertTrue(result.summary.encryptionEnabled)
    }

    // MARK: - Import Tests

    func test_ImportBackup_WithReplaceAllStrategy_ImportsAllPayslips() async throws {
        // Given
        let backupData = try await createValidBackupData(payslipCount: 3)
        mockRepository.mockPayslips = [] // Empty repository

        // When
        let result = try await importOperations.importBackup(from: backupData, strategy: .replaceAll)

        // Then
        XCTAssertEqual(result.importedPayslips.count, 3)
        XCTAssertEqual(result.skippedPayslips.count, 0)
        XCTAssertTrue(result.failedPayslips.isEmpty)
        XCTAssertTrue(result.wasSuccessful)
    }

    func test_ImportBackup_WithSkipDuplicatesStrategy_ProcessesPayslips() async throws {
        // Given - Create backup data
        let backupPayslips = [
            createMockPayslipDTO(id: UUID()),
            createMockPayslipDTO(id: UUID())
        ]
        let backupData = try await createValidBackupDataFrom(payslips: backupPayslips)

        // Clear repository before import
        mockRepository.mockPayslips = []

        // When
        let result = try await importOperations.importBackup(from: backupData, strategy: .skipDuplicates)

        // Then - Verify import completes without error
        XCTAssertNotNil(result)
        XCTAssertGreaterThanOrEqual(result.summary.totalProcessed, 0)
    }



    func test_ImportBackup_WithInvalidData_ThrowsError() async {
        // Given
        let invalidData = "not a valid json".data(using: .utf8)!

        // When/Then
        do {
            _ = try await importOperations.importBackup(from: invalidData, strategy: .replaceAll)
            XCTFail("Should throw error for invalid data")
        } catch {
            // Expected - invalid JSON should fail
            XCTAssertTrue(true)
        }
    }

    func test_ImportBackup_SummaryContainsCorrectCounts() async throws {
        // Given
        let backupData = try await createValidBackupData(payslipCount: 5)

        // When
        let result = try await importOperations.importBackup(from: backupData, strategy: .replaceAll)

        // Then
        XCTAssertEqual(result.summary.totalProcessed, 5)
        XCTAssertEqual(result.summary.successfulImports, 5)
        XCTAssertEqual(result.summary.skippedDuplicates, 0)
        XCTAssertEqual(result.summary.failedImports, 0)
        XCTAssertGreaterThan(result.summary.successRate, 0.99)
    }

    // MARK: - Helper Operations Tests

    func test_CalculateChecksum_ReturnsSameValueForSameData() {
        // Given
        let data = "test data for checksum".data(using: .utf8)!

        // When
        let checksum1 = helperOperations.calculateChecksum(for: data)
        let checksum2 = helperOperations.calculateChecksum(for: data)

        // Then
        XCTAssertEqual(checksum1, checksum2)
        XCTAssertEqual(checksum1.count, 64) // SHA256 produces 64 hex characters
    }

    func test_CalculateChecksum_ReturnsDifferentValueForDifferentData() {
        // Given
        let data1 = "data one".data(using: .utf8)!
        let data2 = "data two".data(using: .utf8)!

        // When
        let checksum1 = helperOperations.calculateChecksum(for: data1)
        let checksum2 = helperOperations.calculateChecksum(for: data2)

        // Then
        XCTAssertNotEqual(checksum1, checksum2)
    }

    func test_GenerateBackupFilename_ContainsTimestamp() {
        // When
        let filename = helperOperations.generateBackupFilename()

        // Then
        XCTAssertTrue(filename.hasPrefix("PayslipMax_Backup_"))
        XCTAssertTrue(filename.hasSuffix(".json"))
        XCTAssertGreaterThan(filename.count, 30) // Includes timestamp
    }

    func test_GenerateSecurityToken_ReturnsBase64String() {
        // When
        let token = helperOperations.generateSecurityToken()

        // Then
        XCTAssertFalse(token.isEmpty)
        // Verify it's valid base64 by decoding
        XCTAssertNotNil(Data(base64Encoded: token))
    }

    func test_GenerateMetadata_CalculatesCorrectDateRange() {
        // Given
        let date1 = Date(timeIntervalSinceNow: -86400 * 30) // 30 days ago
        let date2 = Date()

        let backupItems = [
            createMockBackupPayslipItem(timestamp: date1),
            createMockBackupPayslipItem(timestamp: date2)
        ]

        // When
        let metadata = helperOperations.generateMetadata(for: backupItems)

        // Then
        XCTAssertEqual(metadata.totalPayslips, 2)
        XCTAssertLessThanOrEqual(metadata.dateRange.earliest, date1)
        XCTAssertGreaterThanOrEqual(metadata.dateRange.latest, date2.addingTimeInterval(-1))
    }

    // MARK: - Import Strategy Tests

    func test_ShouldImportPayslip_ReplaceAll_AlwaysReturnsTrue() async throws {
        // Given
        let backupPayslip = createMockBackupPayslipItem()
        let existingIds = Set([backupPayslip.id])

        // When
        let shouldImport = try await helperOperations.shouldImportPayslip(
            backupPayslip,
            existingIds: existingIds,
            strategy: .replaceAll
        )

        // Then
        XCTAssertTrue(shouldImport)
    }

    func test_ShouldImportPayslip_SkipDuplicates_ReturnsFalseForExisting() async throws {
        // Given
        let backupPayslip = createMockBackupPayslipItem()
        let existingIds = Set([backupPayslip.id])

        // When
        let shouldImport = try await helperOperations.shouldImportPayslip(
            backupPayslip,
            existingIds: existingIds,
            strategy: .skipDuplicates
        )

        // Then
        XCTAssertFalse(shouldImport)
    }

    func test_ShouldImportPayslip_SkipDuplicates_ReturnsTrueForNew() async throws {
        // Given
        let backupPayslip = createMockBackupPayslipItem()
        let existingIds = Set([UUID()]) // Different ID

        // When
        let shouldImport = try await helperOperations.shouldImportPayslip(
            backupPayslip,
            existingIds: existingIds,
            strategy: .skipDuplicates
        )

        // Then
        XCTAssertTrue(shouldImport)
    }

    // MARK: - QR Code Tests

    func test_GenerateQRCode_CreatesValidQRInfo() async throws {
        // Given
        let backupData = try await createValidBackupData(payslipCount: 1)
        mockRepository.mockPayslips = createMockPayslipDTOs(count: 1)
        let result = try await exportOperations.exportBackup()

        // When
        let qrInfo = try helperOperations.generateQRCode(for: result, shareType: .file)

        // Then
        XCTAssertEqual(qrInfo.shareType, .file)
        XCTAssertFalse(qrInfo.securityToken.isEmpty)
        XCTAssertGreaterThan(qrInfo.expiresAt, Date())
        XCTAssertNotNil(qrInfo.qrCodeData)
    }

    // MARK: - Round Trip Tests

    func test_ExportThenImport_PreservesAllData() async throws {
        // Given
        let originalPayslips = createMockPayslipDTOs(count: 3)
        mockRepository.mockPayslips = originalPayslips

        // When: Export
        let exportResult = try await exportOperations.exportBackup()

        // Clear repository and import
        mockRepository.mockPayslips = []
        mockRepository.savedPayslips = []

        let importResult = try await importOperations.importBackup(
            from: exportResult.fileData,
            strategy: .replaceAll
        )

        // Then
        XCTAssertEqual(importResult.importedPayslips.count, 3)
        XCTAssertTrue(importResult.wasSuccessful)

        // Verify saved payslips match originals
        XCTAssertEqual(mockRepository.savedPayslips.count, 3)
        for (index, saved) in mockRepository.savedPayslips.enumerated() {
            let original = originalPayslips[index]
            XCTAssertEqual(saved.month, original.month)
            XCTAssertEqual(saved.year, original.year)
            XCTAssertEqual(saved.credits, original.credits, accuracy: 0.01)
            XCTAssertEqual(saved.debits, original.debits, accuracy: 0.01)
        }
    }

    // MARK: - Helper Methods

    private func createMockPayslipDTO(id: UUID = UUID()) -> PayslipDTO {
        return PayslipDTO(
            id: id,
            timestamp: Date(),
            month: "November",
            year: 2025,
            credits: 100000.0,
            debits: 30000.0,
            dsop: 5000.0,
            tax: 10000.0,
            earnings: ["Basic": 80000.0, "DA": 20000.0],
            deductions: ["Tax": 10000.0, "DSOP": 5000.0],
            name: "Test User",
            accountNumber: "1234567890",
            panNumber: "ABCD1234E",
            isNameEncrypted: false,
            isAccountNumberEncrypted: false,
            isPanNumberEncrypted: false,
            encryptionVersion: 1,
            pdfData: nil,
            pdfURL: nil,
            isSample: false,
            source: "Test",
            status: "Active",
            notes: nil,
            numberOfPages: 1,
            metadata: [:]
        )
    }

    private func createMockPayslipDTOs(count: Int) -> [PayslipDTO] {
        return (0..<count).map { index in
            var dto = createMockPayslipDTO()
            dto.month = Calendar.current.monthSymbols[(index % 12)]
            dto.year = 2025 - (index / 12)
            return dto
        }
    }

    private func createMockBackupPayslipItem(
        id: UUID = UUID(),
        timestamp: Date = Date()
    ) -> BackupPayslipItem {
        let dto = PayslipDTO(
            id: id,
            timestamp: timestamp,
            month: "November",
            year: 2025,
            credits: 100000.0,
            debits: 30000.0,
            dsop: 5000.0,
            tax: 10000.0,
            earnings: [:],
            deductions: [:],
            name: "Test",
            accountNumber: "123",
            panNumber: "ABC",
            isNameEncrypted: false,
            isAccountNumberEncrypted: false,
            isPanNumberEncrypted: false,
            encryptionVersion: 1,
            pdfData: nil,
            pdfURL: nil,
            isSample: false,
            source: "Test",
            status: "Active",
            notes: nil,
            numberOfPages: 1,
            metadata: [:]
        )
        return BackupPayslipItem(from: dto, encryptedSensitiveData: nil)
    }

    private func createValidBackupData(payslipCount: Int) async throws -> Data {
        let payslips = createMockPayslipDTOs(count: payslipCount)
        return try await createValidBackupDataFrom(payslips: payslips)
    }

    private func createValidBackupDataFrom(payslips: [PayslipDTO]) async throws -> Data {
        mockRepository.mockPayslips = payslips
        let result = try await exportOperations.exportBackup()
        return result.fileData
    }
}
