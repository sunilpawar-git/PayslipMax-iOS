import XCTest
@testable import PayslipMax

/// Tests for PDF backup and restore functionality
@MainActor
final class PDFBackupRestoreTests: XCTestCase {

    private var mockPDFData: Data!
    private var testPayslipItem: PayslipItem!

    override func setUp() async throws {
        try await super.setUp()
        mockPDFData = PDFBackupTestHelpers.createRealisticPDFData()
        testPayslipItem = PDFBackupTestHelpers.createTestPayslipWithPDF(pdfData: mockPDFData)
    }

    override func tearDown() async throws {
        mockPDFData = nil
        testPayslipItem = nil
        try await super.tearDown()
    }

    // MARK: - Critical Regression Tests

    func testCritical_PayslipDTO_IncludesPDFData() {
        XCTAssertNotNil(testPayslipItem.pdfData)
        let dto = PayslipDTO(from: testPayslipItem)
        XCTAssertNotNil(dto.pdfData)
        XCTAssertEqual(dto.pdfData?.count, mockPDFData.count)
        XCTAssertEqual(dto.pdfData, mockPDFData)
    }

    func testCritical_BackupPayslipItem_IncludesPDFFromDTO() {
        let dto = PayslipDTO(from: testPayslipItem)
        XCTAssertNotNil(dto.pdfData)

        let backupItem = BackupPayslipItem(from: dto, encryptedSensitiveData: nil)
        XCTAssertNotNil(backupItem.pdfData)
        XCTAssertEqual(backupItem.pdfData?.count, mockPDFData.count)
        XCTAssertTrue(backupItem.hasPdfData)
    }

    func testCritical_BackupExport_IncludesPDFData() async throws {
        let repository = MockPDFBackupRepository()
        repository.mockPayslips = [PayslipDTO(from: testPayslipItem)]

        let helper = BackupHelperOperations()
        let exportOps = BackupExportOperations(repository: repository, helperOperations: helper)

        let result = try await exportOps.exportBackup()

        XCTAssertEqual(result.backupFile.payslips.count, 1)
        let exportedPayslip = result.backupFile.payslips.first
        XCTAssertNotNil(exportedPayslip?.pdfData)
        XCTAssertTrue(exportedPayslip?.hasPdfData ?? false)
        XCTAssertGreaterThan(result.fileData.count, 1000)
    }

    func testCritical_BackupImport_RestoresPDFData() async throws {
        let originalDTO = PayslipDTO(from: testPayslipItem)
        let backupItem = BackupPayslipItem(from: originalDTO, encryptedSensitiveData: nil)
        let backupFile = PDFBackupTestHelpers.createMockBackupFile(with: [backupItem])

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let tempData = try encoder.encode(backupFile)

        let helper = BackupHelperOperations()
        let checksum = helper.calculateChecksum(for: tempData)

        let finalBackupFile = PayslipBackupFile(
            version: backupFile.version,
            exportDate: backupFile.exportDate,
            deviceId: backupFile.deviceId,
            encryptionVersion: backupFile.encryptionVersion,
            userName: backupFile.userName,
            payslips: backupFile.payslips,
            metadata: backupFile.metadata,
            checksum: checksum
        )
        let backupData = try encoder.encode(finalBackupFile)

        let repository = MockPDFBackupRepository()
        let importOps = BackupImportOperations(repository: repository, helperOperations: helper)

        _ = try await importOps.importBackup(from: backupData, strategy: .replaceAll)

        XCTAssertEqual(repository.savedPayslips.count, 1)
        XCTAssertNotNil(repository.savedPayslips.first?.pdfData)
        XCTAssertEqual(repository.savedPayslips.first?.pdfData?.count, mockPDFData.count)
    }

    // MARK: - End-to-End Tests

    func testEndToEnd_BackupRestoreCycle_PreservesPDF() async throws {
        let repository = MockPDFBackupRepository()
        repository.mockPayslips = [PayslipDTO(from: testPayslipItem)]

        let helper = BackupHelperOperations()
        let exportOps = BackupExportOperations(repository: repository, helperOperations: helper)
        let importOps = BackupImportOperations(repository: repository, helperOperations: helper)

        let exportResult = try await exportOps.exportBackup()
        repository.mockPayslips = []
        repository.savedPayslips = []

        _ = try await importOps.importBackup(from: exportResult.fileData, strategy: .replaceAll)

        XCTAssertEqual(repository.savedPayslips.count, 1)
        XCTAssertNotNil(repository.savedPayslips.first?.pdfData)
        XCTAssertEqual(repository.savedPayslips.first?.pdfData, mockPDFData)
    }

    func testEndToEnd_MixedPDFBackup() async throws {
        let payslip1 = PayslipDTO(from: testPayslipItem)
        var payslip2 = PayslipDTO(from: testPayslipItem)
        payslip2.pdfData = nil
        var payslip3 = PayslipDTO(from: testPayslipItem)
        payslip3.pdfData = Data(repeating: 0xAB, count: 50000)

        let repository = MockPDFBackupRepository()
        repository.mockPayslips = [payslip1, payslip2, payslip3]

        let helper = BackupHelperOperations()
        let exportOps = BackupExportOperations(repository: repository, helperOperations: helper)

        let result = try await exportOps.exportBackup()

        XCTAssertEqual(result.backupFile.payslips.count, 3)
        XCTAssertNotNil(result.backupFile.payslips[0].pdfData)
        XCTAssertNil(result.backupFile.payslips[1].pdfData)
        XCTAssertNotNil(result.backupFile.payslips[2].pdfData)
        XCTAssertEqual(result.backupFile.payslips[2].pdfData?.count, 50000)
    }

    // MARK: - Edge Case Tests

    func testEdgeCase_LargePDFBackup() async throws {
        let largePDF = Data(repeating: 0xFF, count: 1_000_000)
        testPayslipItem.pdfData = largePDF

        let repository = MockPDFBackupRepository()
        repository.mockPayslips = [PayslipDTO(from: testPayslipItem)]

        let helper = BackupHelperOperations()
        let exportOps = BackupExportOperations(repository: repository, helperOperations: helper)

        let result = try await exportOps.exportBackup()

        XCTAssertNotNil(result.backupFile.payslips.first?.pdfData)
        XCTAssertGreaterThan(result.fileData.count, 1_000_000)
    }

    func testEdgeCase_BackupWithoutPDFs() async throws {
        testPayslipItem.pdfData = nil

        let repository = MockPDFBackupRepository()
        repository.mockPayslips = [PayslipDTO(from: testPayslipItem)]

        let helper = BackupHelperOperations()
        let exportOps = BackupExportOperations(repository: repository, helperOperations: helper)

        let result = try await exportOps.exportBackup()

        XCTAssertNil(result.backupFile.payslips.first?.pdfData)
        XCTAssertFalse(result.backupFile.payslips.first?.hasPdfData ?? true)
    }

    func testEdgeCase_JSONSerializationPreservesPDF() throws {
        let dto = PayslipDTO(from: testPayslipItem)
        let backupItem = BackupPayslipItem(from: dto, encryptedSensitiveData: nil)

        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(backupItem)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(BackupPayslipItem.self, from: jsonData)

        XCTAssertNotNil(decoded.pdfData)
        XCTAssertEqual(decoded.pdfData, mockPDFData)
    }
}
