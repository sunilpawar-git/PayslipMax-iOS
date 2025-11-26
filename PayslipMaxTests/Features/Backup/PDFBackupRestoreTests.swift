import XCTest
@testable import PayslipMax

/// Comprehensive tests for PDF backup and restore functionality
///
/// This test suite ensures that PDFs are properly included in backups and restored correctly.
/// These tests prevent regression of the PDF backup feature added in November 2025.
@MainActor
final class PDFBackupRestoreTests: XCTestCase {

    // MARK: - Test Properties

    private var mockPDFData: Data!
    private var testPayslipItem: PayslipItem!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        mockPDFData = createRealisticPDFData()
        testPayslipItem = createTestPayslipWithPDF(pdfData: mockPDFData)
    }

    override func tearDown() async throws {
        mockPDFData = nil
        testPayslipItem = nil

        try await super.tearDown()
    }

    // MARK: - Critical Regression Tests

    /// CRITICAL: Ensures PayslipDTO now INCLUDES PDF data (changed in Nov 2025)
    /// This is a breaking change from previous behavior where DTOs excluded PDFs
    func testCritical_PayslipDTO_IncludesPDFData() {
        // Given: A PayslipItem with PDF data
        XCTAssertNotNil(testPayslipItem.pdfData, "Setup should include PDF data")

        // When: Converting to PayslipDTO
        let dto = PayslipDTO(from: testPayslipItem)

        // Then: PDF data MUST be included (NEW BEHAVIOR as of Nov 2025)
        XCTAssertNotNil(dto.pdfData, "CRITICAL: PayslipDTO must include PDF data for backup/restore")
        XCTAssertEqual(dto.pdfData?.count, mockPDFData.count, "PDF data size must match")
        XCTAssertEqual(dto.pdfData, mockPDFData, "PDF data content must match exactly")
    }

    /// CRITICAL: Ensures BackupPayslipItem includes PDF from DTO
    func testCritical_BackupPayslipItem_IncludesPDFFromDTO() {
        // Given: A PayslipDTO with PDF data
        let dto = PayslipDTO(from: testPayslipItem)
        XCTAssertNotNil(dto.pdfData, "DTO should have PDF data")

        // When: Creating BackupPayslipItem from DTO
        let backupItem = BackupPayslipItem(from: dto, encryptedSensitiveData: nil)

        // Then: PDF data must be preserved
        XCTAssertNotNil(backupItem.pdfData, "BackupPayslipItem must include PDF data")
        XCTAssertEqual(backupItem.pdfData?.count, mockPDFData.count, "PDF size must match")
        XCTAssertTrue(backupItem.hasPdfData, "hasPdfData flag must be true")
    }

    /// CRITICAL: Tests complete export includes PDF data
    func testCritical_BackupExport_IncludesPDFData() async throws {
        // Given: A payslip with PDF in the repository
        let repository = MockBackupTestRepository()
        repository.mockPayslips = [PayslipDTO(from: testPayslipItem)]

        let helper = BackupHelperOperations()
        let exportOps = BackupExportOperations(repository: repository, helperOperations: helper)

        // When: Exporting backup
        let result = try await exportOps.exportBackup()

        // Then: Backup must contain PDF data
        XCTAssertEqual(result.backupFile.payslips.count, 1, "Should export 1 payslip")

        let exportedPayslip = result.backupFile.payslips.first
        XCTAssertNotNil(exportedPayslip, "Exported payslip should exist")
        XCTAssertNotNil(exportedPayslip?.pdfData, "CRITICAL: Exported payslip must have PDF data")
        XCTAssertTrue(exportedPayslip?.hasPdfData ?? false, "hasPdfData flag should be true")

        // Verify file size includes PDF (should be > 1KB for realistic PDF)
        XCTAssertGreaterThan(result.fileData.count, 1000, "Backup with PDF should be > 1KB")
        XCTAssertGreaterThan(result.summary.fileSize, 1000, "File size summary should reflect PDF")
    }

    /// CRITICAL: Tests complete restore recovers PDF data
    func testCritical_BackupImport_RestoresPDFData() async throws {
        // Given: A backup containing PDF data with proper checksum
        let originalDTO = PayslipDTO(from: testPayslipItem)
        let backupItem = BackupPayslipItem(from: originalDTO, encryptedSensitiveData: nil)

        // Create backup file without checksum first
        let tempBackupFile = createMockBackupFile(with: [backupItem])

        // Encode it to calculate proper checksum (matching export behavior)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let tempData = try encoder.encode(tempBackupFile)
        let helper = BackupHelperOperations()
        let checksum = helper.calculateChecksum(for: tempData)

        // Create final backup file with calculated checksum
        let backupFile = PayslipBackupFile(
            version: tempBackupFile.version,
            exportDate: tempBackupFile.exportDate,
            deviceId: tempBackupFile.deviceId,
            encryptionVersion: tempBackupFile.encryptionVersion,
            userName: tempBackupFile.userName,
            payslips: tempBackupFile.payslips,
            metadata: tempBackupFile.metadata,
            checksum: checksum
        )

        let backupData = try encoder.encode(backupFile)

        // When: Importing backup
        let repository = MockBackupTestRepository()
        let importOps = BackupImportOperations(repository: repository, helperOperations: helper)

        _ = try await importOps.importBackup(from: backupData, strategy: .replaceAll)

        // Then: Imported payslips must have PDF data
        XCTAssertEqual(repository.savedPayslips.count, 1, "Should import 1 payslip")

        let restoredDTO = repository.savedPayslips.first
        XCTAssertNotNil(restoredDTO, "Restored payslip should exist")
        XCTAssertNotNil(restoredDTO?.pdfData, "CRITICAL: Restored payslip must have PDF data")
        XCTAssertEqual(restoredDTO?.pdfData?.count, mockPDFData.count, "Restored PDF size must match")
    }

    // MARK: - End-to-End Tests

    /// Tests complete backup → restore cycle preserves PDF
    func testEndToEnd_BackupRestoreCycle_PreservesPDF() async throws {
        // Given: Original payslip with PDF
        let repository = MockBackupTestRepository()
        repository.mockPayslips = [PayslipDTO(from: testPayslipItem)]

        let helper = BackupHelperOperations()
        let exportOps = BackupExportOperations(repository: repository, helperOperations: helper)
        let importOps = BackupImportOperations(repository: repository, helperOperations: helper)

        // When: Export → Import
        let exportResult = try await exportOps.exportBackup()
        repository.mockPayslips = [] // Clear repository
        repository.savedPayslips = [] // Clear saved

        _ = try await importOps.importBackup(from: exportResult.fileData, strategy: .replaceAll)

        // Then: PDF should be preserved through the cycle
        XCTAssertEqual(repository.savedPayslips.count, 1, "Should restore 1 payslip")

        let restored = repository.savedPayslips.first
        XCTAssertNotNil(restored?.pdfData, "PDF must survive backup/restore cycle")
        XCTAssertEqual(restored?.pdfData, mockPDFData, "PDF content must be identical after cycle")
    }

    /// Tests backup with multiple payslips, some with PDFs, some without
    func testEndToEnd_MixedPDFBackup() async throws {
        // Given: Multiple payslips with varying PDF status
        let payslip1 = PayslipDTO(from: testPayslipItem) // Has PDF
        var payslip2 = PayslipDTO(from: testPayslipItem)
        payslip2.pdfData = nil // No PDF
        var payslip3 = PayslipDTO(from: testPayslipItem)
        payslip3.pdfData = Data(repeating: 0xAB, count: 50000) // Different PDF

        let repository = MockBackupTestRepository()
        repository.mockPayslips = [payslip1, payslip2, payslip3]

        let helper = BackupHelperOperations()
        let exportOps = BackupExportOperations(repository: repository, helperOperations: helper)

        // When: Exporting mixed backup
        let result = try await exportOps.exportBackup()

        // Then: Each payslip should preserve its PDF status
        XCTAssertEqual(result.backupFile.payslips.count, 3, "Should export 3 payslips")

        XCTAssertNotNil(result.backupFile.payslips[0].pdfData, "Payslip 1 should have PDF")
        XCTAssertNil(result.backupFile.payslips[1].pdfData, "Payslip 2 should not have PDF")
        XCTAssertNotNil(result.backupFile.payslips[2].pdfData, "Payslip 3 should have PDF")
        XCTAssertEqual(result.backupFile.payslips[2].pdfData?.count, 50000, "Payslip 3 PDF size correct")
    }

    // MARK: - Edge Case Tests

    /// Tests backup with large PDF data (1MB)
    func testEdgeCase_LargePDFBackup() async throws {
        // Given: Payslip with large PDF (1MB)
        let largePDF = Data(repeating: 0xFF, count: 1_000_000)
        testPayslipItem.pdfData = largePDF

        let repository = MockBackupTestRepository()
        repository.mockPayslips = [PayslipDTO(from: testPayslipItem)]

        let helper = BackupHelperOperations()
        let exportOps = BackupExportOperations(repository: repository, helperOperations: helper)

        // When: Exporting large PDF
        let result = try await exportOps.exportBackup()

        // Then: Should handle large PDF correctly
        XCTAssertNotNil(result.backupFile.payslips.first?.pdfData, "Large PDF should be included")
        XCTAssertGreaterThan(result.fileData.count, 1_000_000, "Backup should be > 1MB")
        XCTAssertEqual(result.backupFile.payslips.first?.pdfData?.count, 1_000_000, "PDF size preserved")
    }

    /// Tests backup without any PDFs (edge case)
    func testEdgeCase_BackupWithoutPDFs() async throws {
        // Given: Payslip without PDF data
        testPayslipItem.pdfData = nil

        let repository = MockBackupTestRepository()
        repository.mockPayslips = [PayslipDTO(from: testPayslipItem)]

        let helper = BackupHelperOperations()
        let exportOps = BackupExportOperations(repository: repository, helperOperations: helper)

        // When: Exporting without PDFs
        let result = try await exportOps.exportBackup()

        // Then: Should still work correctly
        XCTAssertNil(result.backupFile.payslips.first?.pdfData, "No PDF should be nil")
        XCTAssertFalse(result.backupFile.payslips.first?.hasPdfData ?? true, "hasPdfData should be false")
        XCTAssertLessThan(result.fileData.count, 10_000, "Backup without PDF should be small")
    }

    /// Tests JSON serialization preserves PDF data
    func testEdgeCase_JSONSerializationPreservesPDF() throws {
        // Given: BackupPayslipItem with PDF
        let dto = PayslipDTO(from: testPayslipItem)
        let backupItem = BackupPayslipItem(from: dto, encryptedSensitiveData: nil)

        // When: Encoding to JSON and back
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(backupItem)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(BackupPayslipItem.self, from: jsonData)

        // Then: PDF should survive JSON round-trip (Base64 encoded)
        XCTAssertNotNil(decoded.pdfData, "PDF should survive JSON encoding")
        XCTAssertEqual(decoded.pdfData, mockPDFData, "PDF data should match after JSON round-trip")
    }

    // MARK: - File Size Tests

    /// Validates that PDF backup creates reasonably sized files
    func testFileSize_RealisticBackupSizes() async throws {
        // Given: 2 payslips with typical PDFs (100KB each)
        let pdf1 = Data(repeating: 0xAA, count: 100_000)
        let pdf2 = Data(repeating: 0xBB, count: 100_000)

        var payslip1 = PayslipDTO(from: testPayslipItem)
        payslip1.pdfData = pdf1
        var payslip2 = PayslipDTO(from: testPayslipItem)
        payslip2.pdfData = pdf2

        let repository = MockBackupTestRepository()
        repository.mockPayslips = [payslip1, payslip2]

        let helper = BackupHelperOperations()
        let exportOps = BackupExportOperations(repository: repository, helperOperations: helper)

        // When: Exporting backup
        let result = try await exportOps.exportBackup()

        // Then: File size should be reasonable (200KB PDFs + JSON overhead = ~270KB)
        let fileSize = result.fileData.count
        XCTAssertGreaterThan(fileSize, 200_000, "Should be > 200KB (2x100KB PDFs)")
        XCTAssertLessThan(fileSize, 400_000, "Should be < 400KB (Base64 overhead ~33%)")

        // Verify summary reflects actual size
        XCTAssertEqual(result.summary.fileSize, fileSize, "Summary should reflect actual file size")
    }

    // MARK: - Helper Methods

    private func createTestPayslipWithPDF(pdfData: Data) -> PayslipItem {
        let item = PayslipItem(
            id: UUID(),
            timestamp: Date(),
            month: "November",
            year: 2025,
            credits: 100000.0,
            debits: 30000.0,
            dsop: 5000.0,
            tax: 10000.0,
            pdfData: pdfData
        )

        item.earnings = ["Basic Pay": 80000.0, "DA": 20000.0]
        item.deductions = ["Tax": 10000.0, "DSOP": 5000.0, "Other": 15000.0]
        item.name = "Test User"
        item.accountNumber = "1234567890"

        return item
    }

    private func createRealisticPDFData() -> Data {
        // Create a realistic-sized mock PDF (not actual PDF format, just data)
        var pdfData = Data()

        // Add PDF header magic bytes
        pdfData.append(contentsOf: [0x25, 0x50, 0x44, 0x46]) // "%PDF"

        // Add some content (100KB total)
        pdfData.append(Data(repeating: 0x20, count: 100_000 - 4))

        return pdfData
    }

    private func createMockBackupFile(with payslips: [BackupPayslipItem]) -> PayslipBackupFile {
        let earliest = payslips.map { $0.timestamp }.min() ?? Date()
        let latest = payslips.map { $0.timestamp }.max() ?? Date()

        let metadata = BackupMetadata(
            totalPayslips: payslips.count,
            dateRange: BackupDateRange(earliest: earliest, latest: latest),
            estimatedSize: payslips.count * 100_000
        )

        return PayslipBackupFile(
            version: "1.0",
            exportDate: Date(),
            deviceId: "test-device",
            encryptionVersion: 1,
            userName: "Test User",
            payslips: payslips,
            metadata: metadata,
            checksum: ""
        )
    }
}

// MARK: - Mock Repository

/// Mock repository for testing backup operations
@MainActor
private final class MockBackupTestRepository: SendablePayslipRepository {
    var mockPayslips: [PayslipDTO] = []
    var savedPayslips: [PayslipDTO] = []

    func fetchAllPayslips() async throws -> [PayslipDTO] {
        return mockPayslips
    }

    func fetchPayslips(fromDate: Date, toDate: Date) async throws -> [PayslipDTO] {
        return mockPayslips
    }

    func fetchPayslip(byId id: UUID) async throws -> PayslipDTO? {
        return mockPayslips.first { $0.id == id }
    }

    func savePayslip(_ dto: PayslipDTO) async throws -> UUID {
        savedPayslips.append(dto)
        return dto.id
    }

    func updatePayslip(withId id: UUID, from dto: PayslipDTO) async throws -> Bool {
        return true
    }

    func deletePayslip(withId id: UUID) async throws -> Bool {
        return true
    }

    func countPayslips() async throws -> Int {
        return mockPayslips.count
    }
}
