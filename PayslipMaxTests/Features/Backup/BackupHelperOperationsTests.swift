import XCTest
@testable import PayslipMax

/// Tests for BackupHelperOperations functionality
@MainActor
final class BackupHelperOperationsTests: XCTestCase {

    private var helperOperations: BackupHelperOperations!

    override func setUp() async throws {
        try await super.setUp()
        helperOperations = BackupHelperOperations()
    }

    override func tearDown() async throws {
        helperOperations = nil
        try await super.tearDown()
    }

    // MARK: - Checksum Tests

    func test_CalculateChecksum_ReturnsSameValueForSameData() {
        let data = "test data for checksum".data(using: .utf8)!

        let checksum1 = helperOperations.calculateChecksum(for: data)
        let checksum2 = helperOperations.calculateChecksum(for: data)

        XCTAssertEqual(checksum1, checksum2)
        XCTAssertEqual(checksum1.count, 64)
    }

    func test_CalculateChecksum_ReturnsDifferentValueForDifferentData() {
        let data1 = "data one".data(using: .utf8)!
        let data2 = "data two".data(using: .utf8)!

        let checksum1 = helperOperations.calculateChecksum(for: data1)
        let checksum2 = helperOperations.calculateChecksum(for: data2)

        XCTAssertNotEqual(checksum1, checksum2)
    }

    // MARK: - Filename Generation Tests

    func test_GenerateBackupFilename_ContainsTimestamp() {
        let filename = helperOperations.generateBackupFilename()

        XCTAssertTrue(filename.hasPrefix("PayslipMax_Backup_"))
        XCTAssertTrue(filename.hasSuffix(".json"))
        XCTAssertGreaterThan(filename.count, 30)
    }

    func test_GenerateSecurityToken_ReturnsBase64String() {
        let token = helperOperations.generateSecurityToken()

        XCTAssertFalse(token.isEmpty)
        XCTAssertNotNil(Data(base64Encoded: token))
    }

    // MARK: - Metadata Tests

    func test_GenerateMetadata_CalculatesCorrectDateRange() {
        let date1 = Date(timeIntervalSinceNow: -86400 * 30)
        let date2 = Date()

        let backupItems = [
            BackupTestHelpers.createMockBackupPayslipItem(timestamp: date1),
            BackupTestHelpers.createMockBackupPayslipItem(timestamp: date2)
        ]

        let metadata = helperOperations.generateMetadata(for: backupItems)

        XCTAssertEqual(metadata.totalPayslips, 2)
        XCTAssertLessThanOrEqual(metadata.dateRange.earliest, date1)
        XCTAssertGreaterThanOrEqual(metadata.dateRange.latest, date2.addingTimeInterval(-1))
    }

    // MARK: - Import Strategy Tests

    func test_ShouldImportPayslip_ReplaceAll_AlwaysReturnsTrue() async throws {
        let backupPayslip = BackupTestHelpers.createMockBackupPayslipItem()
        let existingIds = Set([backupPayslip.id])

        let shouldImport = try await helperOperations.shouldImportPayslip(
            backupPayslip,
            existingIds: existingIds,
            strategy: .replaceAll
        )

        XCTAssertTrue(shouldImport)
    }

    func test_ShouldImportPayslip_SkipDuplicates_ReturnsFalseForExisting() async throws {
        let backupPayslip = BackupTestHelpers.createMockBackupPayslipItem()
        let existingIds = Set([backupPayslip.id])

        let shouldImport = try await helperOperations.shouldImportPayslip(
            backupPayslip,
            existingIds: existingIds,
            strategy: .skipDuplicates
        )

        XCTAssertFalse(shouldImport)
    }

    func test_ShouldImportPayslip_SkipDuplicates_ReturnsTrueForNew() async throws {
        let backupPayslip = BackupTestHelpers.createMockBackupPayslipItem()
        let existingIds = Set([UUID()])

        let shouldImport = try await helperOperations.shouldImportPayslip(
            backupPayslip,
            existingIds: existingIds,
            strategy: .skipDuplicates
        )

        XCTAssertTrue(shouldImport)
    }

    // MARK: - QR Code Tests

    func test_GenerateQRCode_CreatesValidQRInfo() async throws {
        let mockRepository = MockPayslipRepository()
        mockRepository.mockPayslips = BackupTestHelpers.createMockPayslipDTOs(count: 1)

        let exportOps = BackupExportOperations(
            repository: mockRepository,
            helperOperations: helperOperations
        )
        let result = try await exportOps.exportBackup()

        let qrInfo = try helperOperations.generateQRCode(for: result, shareType: .file)

        XCTAssertEqual(qrInfo.shareType, .file)
        XCTAssertFalse(qrInfo.securityToken.isEmpty)
        XCTAssertGreaterThan(qrInfo.expiresAt, Date())
        XCTAssertNotNil(qrInfo.qrCodeData)
    }
}

