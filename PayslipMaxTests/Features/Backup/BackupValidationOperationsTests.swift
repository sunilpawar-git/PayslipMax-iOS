import XCTest
@testable import PayslipMax

/// Tests for BackupValidationOperations - explicit validation logic testing
@MainActor
final class BackupValidationOperationsTests: XCTestCase {

    // MARK: - Test Properties

    private var sut: BackupValidationOperations!
    private var helperOperations: BackupHelperOperations!
    private var mockRepository: MockPayslipRepository!
    private var exportOperations: BackupExportOperations!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()

        helperOperations = BackupHelperOperations()
        sut = BackupValidationOperations(helperOperations: helperOperations)
        mockRepository = MockPayslipRepository()
        exportOperations = BackupExportOperations(repository: mockRepository, helperOperations: helperOperations)
    }

    override func tearDown() async throws {
        sut = nil
        helperOperations = nil
        mockRepository = nil
        exportOperations = nil
        try await super.tearDown()
    }

    // MARK: - Valid Backup Tests

    func test_validateBackup_WithValidData_ReturnsBackupFile() async throws {
        // Given - Create a valid backup
        let payslips = [createMockPayslipDTO()]
        mockRepository.mockPayslips = payslips
        let exportResult = try await exportOperations.exportBackup()

        // When
        let validatedFile = try await sut.validateBackup(data: exportResult.fileData)

        // Then
        XCTAssertEqual(validatedFile.payslips.count, 1)
        XCTAssertEqual(validatedFile.version, PayslipBackupFile.currentVersion)
        XCTAssertFalse(validatedFile.checksum.isEmpty)
    }

    func test_validateBackup_ChecksVersion() async throws {
        // Given - Create a valid backup and verify version
        let payslips = [createMockPayslipDTO()]
        mockRepository.mockPayslips = payslips
        let exportResult = try await exportOperations.exportBackup()

        // When
        let validatedFile = try await sut.validateBackup(data: exportResult.fileData)

        // Then
        XCTAssertEqual(validatedFile.version, PayslipBackupFile.currentVersion)
    }

    // MARK: - Invalid Data Tests

    func test_validateBackup_WithInvalidJSON_ThrowsError() async {
        // Given
        let invalidData = "not valid json".data(using: .utf8)!

        // When/Then
        do {
            _ = try await sut.validateBackup(data: invalidData)
            XCTFail("Should throw error for invalid JSON")
        } catch {
            // Expected - should throw invalidBackupFile error
            XCTAssertTrue(error is BackupError)
        }
    }

    func test_validateBackup_WithEmptyData_ThrowsError() async {
        // Given
        let emptyData = Data()

        // When/Then
        do {
            _ = try await sut.validateBackup(data: emptyData)
            XCTFail("Should throw error for empty data")
        } catch {
            // Expected
            XCTAssertTrue(true)
        }
    }

    func test_validateBackup_WithMalformedJSON_ThrowsError() async {
        // Given - Valid JSON but not a backup file structure
        let malformedData = "{\"foo\": \"bar\"}".data(using: .utf8)!

        // When/Then
        do {
            _ = try await sut.validateBackup(data: malformedData)
            XCTFail("Should throw error for malformed backup structure")
        } catch {
            // Expected
            XCTAssertTrue(true)
        }
    }

    // MARK: - Metadata Tests

    func test_validateBackup_PreservesMetadata() async throws {
        // Given - Create backup with multiple payslips
        let payslips = [
            createMockPayslipDTO(month: "January", year: 2024),
            createMockPayslipDTO(month: "February", year: 2024),
            createMockPayslipDTO(month: "March", year: 2024)
        ]
        mockRepository.mockPayslips = payslips
        let exportResult = try await exportOperations.exportBackup()

        // When
        let validatedFile = try await sut.validateBackup(data: exportResult.fileData)

        // Then
        XCTAssertEqual(validatedFile.metadata.totalPayslips, 3)
        XCTAssertNotNil(validatedFile.metadata.dateRange)
    }

    func test_validateBackup_ChecksExportDate() async throws {
        // Given
        let beforeExport = Date()
        mockRepository.mockPayslips = [createMockPayslipDTO()]
        let exportResult = try await exportOperations.exportBackup()
        let afterExport = Date()

        // When
        let validatedFile = try await sut.validateBackup(data: exportResult.fileData)

        // Then
        XCTAssertGreaterThanOrEqual(validatedFile.exportDate, beforeExport.addingTimeInterval(-1))
        XCTAssertLessThanOrEqual(validatedFile.exportDate, afterExport.addingTimeInterval(1))
    }

    // MARK: - Payslip Content Tests

    func test_validateBackup_PreservesPayslipData() async throws {
        // Given
        let originalPayslip = createMockPayslipDTO(
            month: "December",
            year: 2025,
            credits: 150000,
            debits: 45000
        )
        mockRepository.mockPayslips = [originalPayslip]
        let exportResult = try await exportOperations.exportBackup()

        // When
        let validatedFile = try await sut.validateBackup(data: exportResult.fileData)

        // Then
        XCTAssertEqual(validatedFile.payslips.count, 1)
        let backupPayslip = validatedFile.payslips[0]
        XCTAssertEqual(backupPayslip.month, "December")
        XCTAssertEqual(backupPayslip.year, 2025)
        XCTAssertEqual(backupPayslip.credits, 150000, accuracy: 0.01)
        XCTAssertEqual(backupPayslip.debits, 45000, accuracy: 0.01)
    }

    // MARK: - Helper Methods

    private func createMockPayslipDTO(
        id: UUID = UUID(),
        month: String = "November",
        year: Int = 2025,
        credits: Double = 100000.0,
        debits: Double = 30000.0
    ) -> PayslipDTO {
        return PayslipDTO(
            id: id,
            timestamp: Date(),
            month: month,
            year: year,
            credits: credits,
            debits: debits,
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
}
